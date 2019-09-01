package ui.common {
	
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
	 * @version  1.1.10
	 * @author   meps
	 */
	public class CGImageProxy {
		
		/** Экземпляр загрузчика */
		public static function get instance():CGImageProxy {
			if (!m_instance)
				m_instance = new CGImageProxy(new ImageProxyLock()); 
			return m_instance;
		}
		
		/** @private */
		public function CGImageProxy(lock:ImageProxyLock) {
			if (!lock)
				throw new Error("Use CGImageProxy.instance for access!");
			m_cache = new Dictionary();
			m_queuePath = new Vector.<String>();
			m_queueListeners = new Vector.<Vector.<IGImage>>();
			m_listenersPath = new Dictionary(true);
			m_loaders = new Array();
			m_timeouts = new Vector.<int>();
			m_timer = new Timer(1);
			m_timer.addEventListener(TimerEvent.TIMER, onTimeout);
		}
		
		/** Загрузить изображение */
		public function load(path:String, target:IGImage):void {
			//trace("CGImageProxy::load", path, printClass(target));
			var index:int, list:Vector.<IGImage>;
			// если уже загружено, сразу вернуть готовый результат
			if (path in m_cache) {
				var result:CGImageResult = m_cache[path];
				if (!result.isUseless()) {
					// успешно загруженные картинки просто отображать
					result.touch();
					//trace("ready", path, printClass(target), printClass(result));
					target.imageUpdate(result);
					//target.call(this, result);
					return;
				}
				// картинки с ошибками уничтожать и перезапрашивать заново
				delete m_cache[path];
				++m_cacheSize;
			}
			// проверить был ли уже подписан этот обработчик на изображение
			var oldPath:String = m_listenersPath[target];
			if (oldPath) {
				//trace("path change", oldPath, "->", path, printClass(target));
				if (oldPath != path) {
					// обработчик привязан к другой картинке, удалить его оттуда
					index = m_queuePath.indexOf(oldPath);
					//trace("path del", index);
					list = m_queueListeners[index];
					index = list.indexOf(target);
					//trace("target del", index);
					list.splice(index, 1);
					// TODO если очередь обработчиков целиком сбросилась, удалить из очереди и изображение
					m_listenersPath[target] = path;
					//trace("path add", path);
				}
			} else {
				// связать обработчик с новым путем
				m_listenersPath[target] = path;
				//trace("path new", path, printClass(target));
			}
			// если еще не загружено, встать в общую очередь
			index = m_queuePath.indexOf(path);
			if (index < 0) {
				// новое изображение
				list = new Vector.<IGImage>();
				list.push(target);
				index = m_queuePath.length;
				m_queuePath[index] = path;
				m_queueListeners[index] = list;
				//trace("new target", index, printClass(target));
			} else {
				// уже стоящее в очереди изображение
				list = m_queueListeners[index];
				if (list.indexOf(target) < 0) {
					//trace("add target", index, printClass(target));
					list.push(target);
				} else {
					//trace("have target", index, printClass(target));
				}
			}
			// подчистить кеш
			doCacheClean();
			doQueueProcess();
		}
		
		/** Отказаться от загрузки изображения */
		public function unload(target:IGImage):void {
			var path:String = m_listenersPath[target];
			//trace("CGImageProxy::unload", path);
			if (path) {
				delete m_listenersPath[target];
				var index:int = m_queuePath.indexOf(path);
				//trace("unload", path, index);
				if (index >= 0) {
					var list:Vector.<IGImage> = m_queueListeners[index];
					index = list.indexOf(target);
					//trace("unload list", index);
					if (index >= 0)
						list.splice(index, 1);
				} else {
					//trace("unload none");
				}
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработать очередь запросов */
		private function doQueueProcess():void {
			// очередь загрузчиков в точности соответствует началу очереди ожидающих загрузки изображений
			var index:int = m_loaders.length; // индекс создаваемого загрузчика
			while (index < LOADER_MAX && index < m_queuePath.length) {
				// добавить загрузчик в список
				var urlLoader:URLLoader = loaderCreate();
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				m_loaders[index] = urlLoader;
				m_timeouts[index] = getTimer() + TIMEOUT_MAX; 
				var path:String = m_queuePath[index];
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
			if (m_cacheSize > 0)
				return;
			for (var path:String in m_cache) {
				var result:CGImageResult = m_cache[path];
				if (result.isUseless()) {
					// здесь не будет коллизий при итерации по изменяемому объекту?
					delete m_cache[path];
					++m_cacheSize;
				}
			}
		}
		
		/** Создать загрузчик и зарегистрировать его события */
		private function loaderCreate():URLLoader {
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.OPEN, onLoaderOpen, false, 0, true);
			urlLoader.addEventListener(Event.COMPLETE, onLoaderComplete, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError, false, 0, true);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError, false, 0, true);
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
			var index:int = m_loaders.indexOf(urlLoader);
			if (index >= 0)
				m_timeouts[index] = 0;
			doTimeoutRestart();
		}
		
		/** Обработчик всех ошибок при загрузке изображения */
		private function onLoaderError(event:Event):void {
			// удалить загрузчик
			var urlLoader:URLLoader = URLLoader(event.target);
			loaderDestroy(urlLoader);
			var index:int = m_loaders.indexOf(urlLoader);
			m_loaders.splice(index, 1);
			m_timeouts.splice(index, 1);
			// ошибка при загрузке изображения
			doImageResult(index);
			doQueueProcess();
		}
		
		/** Обработчик успешной загрузки изображения */
		private function onLoaderComplete(event:Event):void {
			// удалить загрузчик
			var urlLoader:URLLoader = URLLoader(event.target);
			loaderDestroy(urlLoader);
			var index:int = m_loaders.indexOf(urlLoader);
			var data:ByteArray = urlLoader.data;
			if (data && data.length > 0) {
				// переопределить загрузчик и провести загрузку из памяти
				var byteLoader:Loader = new Loader();
				m_loaders[index] = byteLoader;
				m_timeouts[index] = int.MAX_VALUE;
				byteLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBytesComplete);
				byteLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onBytesError);
				byteLoader.loadBytes(data);
			} else {
				// ошибка при загрузке данных
				m_loaders.splice(index, 1);
				m_timeouts.splice(index, 1);
				doImageResult(index);
				doQueueProcess();
			}
		}
		
		/** Обработчик успешной загрузки байт */
		private function onBytesComplete(event:Event):void {
			var byteLoader:Loader = LoaderInfo(event.target).loader;
			var index:int = removeByteLoader(byteLoader);
			// использовать загруженные данные
			doImageResult(index, byteLoader.content);
			doQueueProcess();
		}
		
		/** Обработчик ошибки при загрузке байт */
		private function onBytesError(event:Event):void {
			var index:int = removeByteLoader(LoaderInfo(event.target).loader);
			// ошибка при загрузке из памяти
			doImageResult(index);
			doQueueProcess();
		}
		
		/** Удалить загрузчик */
		private function removeByteLoader(byteLoader:Loader):int {
			byteLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onBytesComplete);
			byteLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onBytesError);
			var index:int = m_loaders.indexOf(byteLoader);
			m_loaders.splice(index, 1);
			m_timeouts.splice(index, 1);
			return index;
		}
		
		/** Перенести изображение из очереди загрузки в кеш */
		private function doImageResult(index:int, data:DisplayObject = null):void {
			// добавить изображение в кеш
			var path:String = m_queuePath[index];
			var result:CGImageResult = new CGImageResult(path, data);
			m_cache[path] = result;
			--m_cacheSize;
			// удалить изображение из очереди
			m_queuePath.splice(index, 1);
			// вызвать все обработчики
			var targets:Vector.<IGImage> = m_queueListeners[index];
			m_queueListeners.splice(index, 1);
			for each (var target:IGImage in targets) {
				delete m_listenersPath[target]; // отвязать обработчик от пути
				//trace("result", path, printClass(result), printClass(func));
				target.imageUpdate(result);
				//func.call(this, result);
			}
		}
		
		/** Обработка наступивших таймаутов и установка нового времени ожидания */
		private function doTimeoutRestart():void {
			m_timer.stop();
			while (true) {
				var index:int = minTimeoutIndex();
				if (index < 0)
					// таймаутов нет
					return;
				// проверить текущий наименьший таймаут
				var time:int = m_timeouts[index] - getTimer();
				if (time > TIMEOUT_MIN) {
					// таймаут еще не наступил, начать его ожидание
					m_timer.delay = time;
					m_timer.start();
					return;
				}
				// таймаут наступил, отработать его сразу
				var urlLoader:URLLoader = m_loaders[index];
				loaderDestroy(urlLoader);
				m_loaders.splice(index, 1);
				m_timeouts.splice(index, 1);
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
			var len:int = m_timeouts.length; 
			if (len == 0)
				// загрузчиков нет
				return -1;
			var minIndex:int = 0;
			var minTime:int = m_timeouts[minIndex];
			for (var index:int = 0; index < len; ++index) {
				var time:int = m_timeouts[index];
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
		private var m_cache:Dictionary/*CGImageResult*/;
		
		/** Оставшееся место для хранения */
		private var m_cacheSize:int = CACHE_SIZE;
		
		/** Очередь загружаемых изображений */
		private var m_queuePath:Vector.<String>;
		
		/** Обработчики запрошенных изображений */
		private var m_queueListeners:Vector.<Vector.<IGImage>>;
		
		/** Связь между обработчиком и путем к изображению */
		private var m_listenersPath:Dictionary/*String*/;
		
		/** Загрузчики для параллельной обработки */
		private var m_loaders:Array;
		
		/** Интервалы времени ожидания загрузки */
		private var m_timeouts:Vector.<int>;
		
		/** Общий таймер, ожидающий минимальный таймаут */
		private var m_timer:Timer;
		
		private static var m_instance:CGImageProxy;
		
		private static const LOADER_MAX:int = 5; // максимальное одновременное количество загрузчиков
		private static const TIMEOUT_MAX:int = 3000; // таймаут до начала загрузки изображения
		private static const TIMEOUT_MIN:int = 50; // допустимое отклонение от таймаута
		private static const CACHE_SIZE:int = 300; // максимальное количество хранящихся изображений
		
	}
	
}

internal class ImageProxyLock {
}
