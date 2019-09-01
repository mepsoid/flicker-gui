package framework.gui {
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	/**
	 * Кеширующий загрузчик изображений
	 * 
	 * @version  1.1.14
	 * @author   meps
	 */
	public class CGImageProxy {
		
		/** Экземпляр загрузчика */
		public static function get instance():CGImageProxy {
			if (!mInstance)
				mInstance = new CGImageProxy(new ImageProxyLock()); 
			return mInstance;
		}
		
		/** @private */
		public function CGImageProxy(lock:ImageProxyLock) {
			if (!lock)
				throw new Error("Use CGImageProxy.instance for access!");
			mCache = new Dictionary();
			mQueuePath = new Vector.<String>();
			mQueueListeners = new Vector.<Vector.<IGImage>>();
			mListenersPath = new Dictionary(true);
			mLoaders = new Array();
			mTimeouts = new Vector.<int>();
			mTimer = new Timer(1);
			mTimer.addEventListener(TimerEvent.TIMER, onTimeout);
		}
		
		/** Загрузить изображение */
		public function load(path:String, target:IGImage):void {
			var index:int, list:Vector.<IGImage>;
			// если уже загружено, сразу вернуть готовый результат
			if (path in mCache) {
				var result:CGImageResult = mCache[path];
				if (!result.isUseless()) {
					// успешно загруженные картинки просто отображать
					result.touch();
					target.imageUpdate(result);
					//target.call(this, result);
					return;
				}
				// картинки с ошибками уничтожать и перезапрашивать заново
				delete mCache[path];
				++mCacheSize;
			}
			// проверить был ли уже подписан этот обработчик на изображение
			var oldPath:String = mListenersPath[target];
			if (oldPath) {
				if (oldPath != path) {
					// обработчик привязан к другой картинке, удалить его оттуда
					index = mQueuePath.indexOf(oldPath);
					list = mQueueListeners[index];
					index = list.indexOf(target);
					list.splice(index, 1);
					// TODO если очередь обработчиков целиком сбросилась, удалить из очереди и изображение
					mListenersPath[target] = path;
				}
			} else {
				// связать обработчик с новым путем
				mListenersPath[target] = path;
			}
			// если еще не загружено, встать в общую очередь
			index = mQueuePath.indexOf(path);
			if (index < 0) {
				// новое изображение
				list = new Vector.<IGImage>();
				list.push(target);
				index = mQueuePath.length;
				mQueuePath[index] = path;
				mQueueListeners[index] = list;
			} else {
				// уже стоящее в очереди изображение
				list = mQueueListeners[index];
				if (list.indexOf(target) < 0) {
					list.push(target);
				}
			}
			// подчистить кеш
			doCacheClean();
			doQueueProcess();
		}
		
		/** Отказаться от загрузки изображения */
		public function unload(target:IGImage):void {
			var path:String = mListenersPath[target];
			if (path) {
				delete mListenersPath[target];
				var index:int = mQueuePath.indexOf(path);
				if (index >= 0) {
					var list:Vector.<IGImage> = mQueueListeners[index];
					index = list.indexOf(target);
					if (index >= 0)
						list.splice(index, 1);
				}
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработать очередь запросов */
		private function doQueueProcess():void {
			// очередь загрузчиков в точности соответствует началу очереди ожидающих загрузки изображений
			var index:int = mLoaders.length; // индекс создаваемого загрузчика
			while (index < LOADER_MAX && index < mQueuePath.length) {
				// добавить загрузчик в список
				var urlLoader:URLLoader = loaderCreate();
				mLoaders[index] = urlLoader;
				mTimeouts[index] = getTimer() + TIMEOUT_MAX; 
				var path:String = mQueuePath[index];
				var request:URLRequest = new URLRequest(path);
				// начать загрузку
				try {
					urlLoader.load(request);
				} catch (error:Error) {
					// загрузчик не смог начать загрузку
					loaderDestroy(urlLoader);
					doImageResult(index);
					continue;
				}
				++index;
				// перезапустить таймаут
				doTimeoutRestart();
			}
		}
		
		/** Очистить кеш при необходимости */
		private function doCacheClean():void {
			if (mCacheSize > 0)
				return;
			for (var path:String in mCache) {
				var result:CGImageResult = mCache[path];
				if (result.isUseless()) {
					// здесь не будет коллизий при итерации по изменяемому объекту?
					delete mCache[path];
					++mCacheSize;
				}
			}
		}
		
		/** Создать загрузчик и зарегистрировать его события */
		private function loaderCreate():URLLoader {
			try {
				var urlLoader:URLLoader = new URLLoader(null);
			} catch (error:Error) {
				// проигнорировать все ошибки
			}
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener(Event.OPEN, onLoaderOpen);
			urlLoader.addEventListener(Event.COMPLETE, onLoaderComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
			return urlLoader;
		}
		
		/** Отписаться от всех событий загрузчика */
		private function loaderDestroy(urlLoader:URLLoader):void {
			urlLoader.removeEventListener(Event.OPEN, onLoaderOpen);
			urlLoader.removeEventListener(Event.COMPLETE, onLoaderComplete);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
		}
		
		/** Обработчик начала загрузки для сброса таймаута */
		private function onLoaderOpen(event:Event):void {
			var urlLoader:URLLoader = URLLoader(event.target);
			var index:int = mLoaders.indexOf(urlLoader);
			if (index >= 0)
				mTimeouts[index] = 0;
			doTimeoutRestart();
		}
		
		/** Обработчик всех ошибок при загрузке изображения */
		private function onLoaderError(event:Event):void {
			// удалить загрузчик
			var urlLoader:URLLoader = URLLoader(event.target);
			loaderDestroy(urlLoader);
			var index:int = mLoaders.indexOf(urlLoader);
			// ошибка при загрузке изображения
			doImageResult(index);
			doQueueProcess();
		}
		
		/** Обработчик успешной загрузки изображения */
		private function onLoaderComplete(event:Event):void {
			// удалить загрузчик
			var urlLoader:URLLoader = URLLoader(event.target);
			loaderDestroy(urlLoader);
			var index:int = mLoaders.indexOf(urlLoader);
			var data:ByteArray = urlLoader.data;
			if (data && data.length > 0) {
				// переопределить загрузчик и провести загрузку из памяти
				var byteLoader:Loader = new Loader();
				mLoaders[index] = byteLoader;
				mTimeouts[index] = int.MAX_VALUE;
				byteLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBytesComplete);
				byteLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onBytesError);
				byteLoader.loadBytes(data);
			} else {
				// ошибка при загрузке данных
				doImageResult(index);
				doQueueProcess();
			}
		}
		
		/** Обработчик успешной загрузки байт */
		private function onBytesComplete(event:Event):void {
			var byteLoader:Loader = LoaderInfo(event.target).loader;
			removeByteLoader(byteLoader);
			var index:int = mLoaders.indexOf(byteLoader);
			// использовать загруженные данные
			doImageResult(index, byteLoader.content);
			doQueueProcess();
		}
		
		/** Обработчик ошибки при загрузке байт */
		private function onBytesError(event:Event):void {
			var byteLoader:Loader = LoaderInfo(event.target).loader;
			removeByteLoader(byteLoader);
			var index:int = mLoaders.indexOf(byteLoader);
			// ошибка при загрузке из памяти
			doImageResult(index);
			doQueueProcess();
		}
		
		/** Удалить загрузчик */
		private function removeByteLoader(byteLoader:Loader):void {
			byteLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onBytesComplete);
			byteLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onBytesError);
		}
		
		/** Перенести изображение из очереди загрузки в кеш */
		private function doImageResult(index:int, data:DisplayObject = null):void {
			mLoaders.splice(index, 1);
			mTimeouts.splice(index, 1);
			// добавить изображение в кеш
			var path:String = mQueuePath[index];
			var result:CGImageResult = new CGImageResult(path, data);
			mCache[path] = result;
			--mCacheSize;
			// удалить изображение из очереди
			mQueuePath.splice(index, 1);
			// вызвать все обработчики
			var targets:Vector.<IGImage> = mQueueListeners[index];
			mQueueListeners.splice(index, 1);
			for each (var target:IGImage in targets) {
				delete mListenersPath[target]; // отвязать обработчик от пути
				target.imageUpdate(result);
			}
		}
		
		/** Обработка наступивших таймаутов и установка нового времени ожидания */
		private function doTimeoutRestart():void {
			mTimer.stop();
			while (true) {
				var index:int = minTimeoutIndex();
				if (index < 0)
					// таймаутов нет
					return;
				// проверить текущий наименьший таймаут
				var time:int = mTimeouts[index] - getTimer();
				if (time > TIMEOUT_MIN) {
					// таймаут еще не наступил, начать его ожидание
					mTimer.delay = time;
					mTimer.start();
					return;
				}
				// таймаут наступил, отработать его сразу
				var urlLoader:URLLoader = mLoaders[index];
				loaderDestroy(urlLoader);
				// изображение не было загружено за выделенное время
				doImageResult(index);
			}
		}
		
		/** Обработчик таймаута до начала загрузки изображения */
		private function onTimeout(event:TimerEvent):void {
			// сработал таймаут по минимальному значению
			doTimeoutRestart();
			doQueueProcess();
		}
		
		/** Найти индекс наименьшего таймаута, либо -1 если все таймауты сброшены */
		private function minTimeoutIndex():int {
			var len:int = mTimeouts.length; 
			if (len == 0)
				// загрузчиков нет
				return -1;
			var minIndex:int = 0;
			var minTime:int = mTimeouts[minIndex];
			for (var index:int = 0; index < len; ++index) {
				var time:int = mTimeouts[index];
				if (time == 0 || minTime <= time)
					continue;
				minIndex = index;
				minTime = time;
			}
			if (minTime == 0)
				// все таймауты сброшены
				return -1;
			return minIndex;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Уже загруженные изображения */
		private var mCache:Dictionary/*CGImageResult*/;
		
		/** Оставшееся место для хранения */
		private var mCacheSize:int = CACHE_SIZE;
		
		/** Очередь загружаемых изображений */
		private var mQueuePath:Vector.<String>;
		
		/** Обработчики запрошенных изображений */
		private var mQueueListeners:Vector.<Vector.<IGImage>>;
		
		/** Связь между обработчиком и путем к изображению */
		private var mListenersPath:Dictionary/*String*/;
		
		/** Загрузчики для параллельной обработки */
		private var mLoaders:Array;
		
		/** Интервалы времени ожидания загрузки */
		private var mTimeouts:Vector.<int>;
		
		/** Общий таймер, ожидающий минимальный таймаут */
		private var mTimer:Timer;
		
		private static var mInstance:CGImageProxy;
		
		private static const LOADER_MAX:int = 15; // максимальное одновременное количество загрузчиков
		private static const TIMEOUT_MAX:int = 5000; // таймаут до начала загрузки изображения
		private static const TIMEOUT_MIN:int = 50; // допустимое отклонение от таймаута
		private static const CACHE_SIZE:int = 300; // максимальное количество хранящихся изображений
		
	}
	
}

internal class ImageProxyLock {
}
