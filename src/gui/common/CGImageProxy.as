package ui.common {
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	/**
	 * Кеширующий загрузчик изображений
	 * 
	 * @version  1.0.3
	 * @author   meps
	 */
	internal class CGImageProxy {
		
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
			m_queueListeners = new Vector.<Vector.<Function>>();
			m_listenersPath = new Dictionary(true);
			m_loaders = new Vector.<Loader>();
			m_timeouts = new Vector.<int>();
			m_timer = new Timer(1);
			m_timer.addEventListener(TimerEvent.TIMER, onTimeout);
			m_context = new LoaderContext(false, ApplicationDomain.currentDomain);
		}
		
		/** Загрузить изображение */
		public function load(path:String, listener:Function):void {
			var index:int, list:Vector.<Function>;
			// если уже загружено, сразу вернуть готовый результат
			if (m_cache.hasOwnProperty(path)) {
				var result:CGImageResult = m_cache[path];
				listener.call(this, result.clone());
				//listener.call(this, result);
				return;
			}
			// проверить был ли уже подписан этот обработчик на изображение
			if (m_listenersPath.hasOwnProperty(listener)) {
				var oldPath:String = m_listenersPath[listener];
				if (oldPath != path) {
					// обработчик привязан к другой картинке, удалить его оттуда
					index = m_queuePath.indexOf(oldPath);
					list = m_queueListeners[index];
					index = list.indexOf(listener);
					list.splice(index, 1);
					m_listenersPath[listener] = path;
				}
			} else {
				// связать обработчик с новым путем
				m_listenersPath[listener] = path;
			}
			// если еще не загружено, встать в общую очередь
			index = m_queuePath.indexOf(path);
			if (index < 0) {
				// новое изображение
				index = m_queuePath.length;
				m_queuePath[index] = path;
				m_queueListeners[index] = Vector.<Function>([listener]);
			} else {
				// уже стоящее в очереди изображение
				list = m_queueListeners[index];
				if (list.indexOf(listener) < 0)
					list.push(listener);
			}
			doQueueProcess();
		}
		
		/** Разместить изображение из памяти */
		/*
		public function place(source:*, listener:Function):void {
			var cls:Class;
			if (source is DisplayObject) {
				// явно переданный отображаемый объект
				listener.call(this, new CGImageResult(null, source as DisplayObject));
				return;
			} else if (source is BitmapData) {
				// растровые данные
				var bitmap:Bitmap = new Bitmap(source as BitmapData);
				bitmap.smoothing = true;
				listener.call(this, new CGImageResult(null, bitmap));
				return;
			} else if (source is ByteArray) {
				// указатель на встроенный или уже загруженный ресурс
				loaderCreate();
				try {
					m_loader.loadBytes(source as ByteArray);
				} catch (r:Error) {
					onLoaderError();
					return false;
				}
				return;
			} else if (source is Class) {
				// указатель на класс
				cls = source as Class;
			} else if (source is String) {
				// имя класса
				try {
					cls = getDefinitionByName(source as String) as Class;
				} catch (r:Error) {
					onLoaderError();
					return;
				}
			} else {
				// неведомые данные не загружаются
				listener.call(this, new CGImageResult(null));
				return;
			}
			if (!cls) {
				listener.call(this, new CGImageResult(null));
				return;
			}
			var graph:DisplayObject = new cls() as DisplayObject;
			if (!graph) {
				listener.call(this, new CGImageResult(null));
				return;
			}
			listener.call(this, new CGImageResult(null, graph));
		}
		*/
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработать очередь запросов */
		private function doQueueProcess():void {
			// очередь загрузчиков в точности соответствует началу очереди ожидающих загрузки изображений
			var index:int = m_loaders.length; // индекс создаваемого загрузчика
			while (index < LOADER_MAX && index < m_queuePath.length) {
				var path:String = m_queuePath[index];
				var request:URLRequest = new URLRequest(path);
				var loader:Loader = loaderCreate();
				try {
					loader.load(request, m_context);
				} catch (error:Error) {
					// загрузчик не смог начать загрузку
					loaderDestroy(loader);
					loader.unload();
					doImageResult(index);
					continue;
				}
				// загрузка началась, добавить загрузчик в список
				m_loaders[index] = loader;
				m_timeouts[index] = getTimer() + TIMEOUT_MAX; 
				++index;
				// перезапустить таймаут
				doTimeoutRestart();
			}
		}
		
		/** Создать загрузчик и зарегистрировать его события */
		private function loaderCreate():Loader {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.OPEN, onLoaderOpen, false, 0, true);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete, false, 0, true);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError, false, 0, true);
			return loader;
		}
		
		/** Отписаться от всех событий загрузчика */
		private function loaderDestroy(loader:Loader):void {
			loader.contentLoaderInfo.removeEventListener(Event.OPEN, onLoaderOpen);
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
		}
		
		/** Обработчик начала загрузки для сброса таймаута */
		private function onLoaderOpen(event:Event):void {
			var loader:Loader = (event.target as LoaderInfo).loader;
			var index:int = m_loaders.indexOf(loader);
			if (index >= 0)
				m_timeouts[index] = 0;
			doTimeoutRestart();
		}
		
		/** Обработчик успешной загрузки изображения */
		private function onLoaderComplete(event:Event):void {
			// удалить загрузчик
			var loader:Loader = (event.target as LoaderInfo).loader;
			loaderDestroy(loader);
			var index:int = m_loaders.indexOf(loader);
			m_loaders.splice(index, 1);
			m_timeouts.splice(index, 1);
			// обработать изображение
			var data:DisplayObject = loader.content;
			doImageResult(index, data);
			doQueueProcess();
		}
		
		/** Обработчик всех ошибок при загрузке изображения */
		private function onLoaderError(event:Event):void {
			// удалить загрузчик
			var loader:Loader = (event.target as LoaderInfo).loader;
			loaderDestroy(loader);
			loader.unload();
			var index:int = m_loaders.indexOf(loader);
			m_loaders.splice(index, 1);
			m_timeouts.splice(index, 1);
			// обработать изображение
			doImageResult(index);
			doQueueProcess();
		}
		
		/** Перенести изображение из очереди загрузки в кеш */
		private function doImageResult(index:int, data:DisplayObject = null):void {
			// добавить изображение в кеш
			var path:String = m_queuePath[index];
			var result:CGImageResult = new CGImageResult(path, data);
			m_cache[path] = result;
			// удалить изображение из очереди
			m_queuePath.splice(index, 1);
			// вызвать все обработчики
			var listeners:Vector.<Function> = m_queueListeners[index];
			m_queueListeners.splice(index, 1);
			for each (var func:Function in listeners) {
				delete m_listenersPath[func]; // отвязать обработчик от пути
				func.call(this, result.clone());
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
				var loader:Loader = m_loaders[index];
				loaderDestroy(loader);
				loader.unload();
				m_loaders.splice(index, 1);
				m_timeouts.splice(index, 1);
				// обработать изображение
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
		
		/** Очередь загружаемых изображений */
		private var m_queuePath:Vector.<String>;
		
		/** Обработчики запрошенных изображений */
		private var m_queueListeners:Vector.<Vector.<Function>>;
		
		/** Связь между обработчиком и путем к изображению */
		private var m_listenersPath:Dictionary/*String*/;
		
		/** Загрузчики для параллельной обработки */
		private var m_loaders:Vector.<Loader>;
		
		/** Интервалы времени ожидания загрузки */
		private var m_timeouts:Vector.<int>;
		
		/** Общий таймер, ожидающий минимальный таймаут */
		private var m_timer:Timer;
		
		/** Контекст загрузчиков */
		private var m_context:LoaderContext;
		
		private static var m_instance:CGImageProxy;
		
		private static const LOADER_MAX:int = 5; // максимальное одновременное количество загрузчиков
		private static const TIMEOUT_MAX:int = 3000; // таймаут до начала загрузки изображения
		private static const TIMEOUT_MIN:int = 50; // допустимое отклонение от таймаута
		
	}
	
}

internal class ImageProxyLock {
}
