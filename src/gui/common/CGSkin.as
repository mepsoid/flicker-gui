package ui.common {
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	
	/**
	 * Менеджер скинов
	 * 
	 * TODO можно при регистрации файлов и ембедов дополнить их списком идентификаторов связанных ресурсов и производить
	 * реальную загрузку файлов только по факту использования этих ресурсов (наличие соответствующих активных колбеков в
	 * словарях), при запросе еще не загруженного ресурса автоматически переходить к подгрузке связанного с ним файла;
	 * файлы, для которых список внутренних ресурсов не перечислен, всегда загружать полностью при переключении скинов
	 * 
	 * @version  1.2.15
	 * @author   meps
	 */
	public class CGSkin extends CGDispatcher {
		
		public static const EVENT_START:String = "skin_change_start"; // событие начала смены скина
		public static const EVENT_PROGRESS:String = "skin_change_progress"; // событие процесса загрузки и смены скина
		public static const EVENT_FINISH:String = "skin_change_finish"; // событие завершения смены скина
		public static const EVENT_ERROR:String = "skin_change_error"; // событие ошибки при смене скина
		
		public static function get instance():CGSkin {
			if (!m_instance)
				m_instance = new CGSkin(new TSkinLock());
			return m_instance;
		}
		
		public function CGSkin(lock:TSkinLock) {
			if (!lock)
				throw new Error("Use CGSkin.instance for access!");
			m_idList = new Dictionary();
			m_listeners = new Vector.<Function>();
			m_skinList = new Vector.<String>();
			m_skinDescriptors = new Dictionary();
			m_loaders = new Dictionary();
		}
		
		/** Подписаться на обновление ресурса */
		public function connect(resourceId:String, target:IGSkinnable):void {
			//trace("test");
			var targets:Dictionary;
			if (m_idList.hasOwnProperty(resourceId)) {
				targets = m_idList[resourceId];
				if (target in targets)
					// подписывать только отсутствующий обработчик
					return;
			} else {
				targets = new Dictionary(true);
				m_idList[resourceId] = targets;
			}
			targets[target] = true;
			// сразу же вызвать обработчик, чтобы элемент интерфейса обновился
			var data:* = resourceCreate(resourceId);
			target.skinUpdate(resourceId, data);
		}
		
		/** Отказаться от подписки; указатель на функцию передается, поскольку
		 * на один идентификатор может быть подписано несколько различных
		 * элементов интерфейса */
		public function disconnect(resourceId:String, target:IGSkinnable):void {
			if (!m_idList.hasOwnProperty(resourceId))
				return;
			var targets:Dictionary = m_idList[resourceId];
			delete targets[target];
		}
		
		/** Подписаться на смену скина */
		public function listen(listener:Function):void {
			if (m_listeners.indexOf(listener) >= 0)
				return;
			m_listeners.push(listener);
		}
		
		/** Отказаться от подписки на смену скина */
		public function unlisten(listener:Function):void {
			var index:int = m_listeners.indexOf(listener);
			if (index < 0)
				return;
			var len:int = m_listeners.length - 1;
			m_listeners[index] = m_listeners[len];
			m_listeners.length = len;
		}
		
		/** Получить дескриптор скина по идентификатору; если дескриптора еще не
		 * существует, он создается */
		public function skinGet(id:String):CGSkinDescriptor {
			if (id in m_skinDescriptors)
				return m_skinDescriptors[id];
			var skin:CGSkinDescriptor = new CGSkinDescriptor(id);
			m_skinDescriptors[id] = skin;
			m_skinList.push(id);
			return skin;
		}
		
		/** Список идентификаторов всех добавленных скинов */
		public function get skinList():Vector.<String> {
			return m_skinList.concat();
		}
		
		/** Текущий скин */
		public function get skinSelect():String {
			return m_skinCurrent;
		}
		
		public function set skinSelect(id:String):void {
			var loader:Loader;
			if (!(id in m_skinDescriptors) || id == m_skinCurrent || id == m_skinTarget || m_filesLeft > 0)
				// желаемого скина нет, выбирается он же, либо загрузка предыдущего еще не окончена
				return;
			m_skinTarget = id;
			// событие начала обновления скина
			eventSend(new CGEvent(EVENT_START));
			// набрать в очередь загрузки отсутствующие файлы ресурсов
			var currentSkin:CGSkinDescriptor = m_skinDescriptors[m_skinTarget];
			m_filesTotal = 0;
			// поставить на загрузку внешние файлы
			var path:String = currentSkin.fileFirst();
			while (path) {
				if (!(path in m_loaders)) {
					++m_filesTotal;
					// такого загрузчика еще нет в очереди
					loader = new Loader(); 
					m_loaders[path] = loader;
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
					loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
					loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
					// FIXME временное решение для борьбы с кешированием в онлайновой версии
					var ts:Date = new Date();
					var pathNoCache:String = path + "?timestamp=" +
						ts.fullYear +
						((ts.month < 9 ? "0" : "") + (ts.month + 1)) +
						((ts.date < 10 ? "0" : "") + ts.date) +
						((ts.hours < 10 ? "0" :"" ) + ts.hours) +
						((ts.minutes < 10 ? "0" : "") + ts.minutes);
					loader.load(new URLRequest(pathNoCache), new LoaderContext(false, new ApplicationDomain()));
				}
				path = currentSkin.fileNext();
			}
			// подсчитать количество эмбеженных файлов отдельно, поскольку их
			// колбеки начнут срабатывать синхронно с запросами встроенных ресурсов
			var embed:Class = currentSkin.embedFirst();
			while (embed) {
				if (!(embed in m_loaders))
					++m_filesTotal;
				embed = currentSkin.embedNext();
			}
			m_filesLeft = m_filesTotal;
			// загрузить классы с ресурсами
			embed = currentSkin.embedFirst();
			while (embed) {
				if (!(embed in m_loaders)) {
					// такой ресурс еще не был загружен и создан
					loader = new Loader();
					m_loaders[embed] = loader;
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
					loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
					loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
					loader.loadBytes(new embed(), new LoaderContext(false, new ApplicationDomain()));
				}
				embed = currentSkin.embedNext();
			}
			if (m_filesLeft == 0)
				// внешних файлов нет
				doSkinReady();
		}
		
		/** Соотношение загруженного объема */
		public function get ratio():Number {
			return m_filesRatio;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обновить элементы интерфейса, связанные с заданным ресурсом */
		private function update(resourceId:String):void {
			//trace("test");
			if (!m_idList.hasOwnProperty(resourceId))
				return;
			var targets:Dictionary = m_idList[resourceId];
			for (var target:Object in targets) {
				var data:* = resourceCreate(resourceId);
				// null является допустимым значением в качестве данных запрошенного ресурса
				IGSkinnable(target).skinUpdate(resourceId, data);
			}
		}
		
		/** Обновить все элементы интерфейса */
		private function updateAll():void {
			//trace("update all items!");
			for (var resourceId:String in m_idList)
				update(resourceId);
			// сообщить всем подписчикам об обновлении скина
			for each (var func:Function in m_listeners)
				func();
		}
		
		/** Создать ресурс по идентификатору */
		private function resourceCreate(resourceId:String):* {
			var cl:Class, key:Object, loader:Loader, domain:ApplicationDomain;
			var currentSkin:CGSkinDescriptor = m_skinDescriptors[m_skinCurrent];
			if (!currentSkin) {
				// еще не подгружен ни один скин, воссоздавать ресурсы из текущего домена
				try {
					// попробовать создать ресурс, используя идентификатор в качестве имени класса
					cl = getDefinitionByName(resourceId) as Class;
				} catch (error:Error) {
					trace(error.message);
					return null;
				}
				if (!cl)
					return null;
				return new cl();
			}
			var className:String = currentSkin.resourceGet(resourceId);
			if (!className)
				// не найден идентификатор класса ресурса
				return null;
			try {
				// сначала попытаться найти ресурс только в новом скине
				for (key in m_loaders)
					if (currentSkin.fileHave(key as String) || currentSkin.embedHave(key as Class)) {
						// попробовать использовать данный файл, если он перечислен в текущем скине как источник ресурсов
						loader = m_loaders[key];
						domain  = loader.contentLoaderInfo.applicationDomain;
						if (domain.hasDefinition(className)) {
							cl = domain.getDefinition(className) as Class; 
							break; // прервать поиск, поскольку нам достаточно первого найденного класса
						}
					}
				// попытаться найти ресурс в корневом домене
				if (cl == null)
					cl = getDefinitionByName(className) as Class;
				// попытаться найти ресурс даже в старом скине; ситуация возникает, когда новый скин еще не загружен, но ресурс запрашивается
				if (cl == null)
					for (key in m_loaders)
						if (!currentSkin.fileHave(key as String) && !currentSkin.embedHave(key as Class)) {
							// использовать файлы чужого скина, которые изначально были проигнорированы
							loader = m_loaders[key];
							domain = loader.contentLoaderInfo.applicationDomain;
							if (domain.hasDefinition(className)) {
								cl = domain.getDefinition(className) as Class; 
								break; // прервать поиск, поскольку нам достаточно первого найденного класса
							}
						}
			} catch (error:Error) {
				trace(error.message, className);
				return null;
			}
			if (!cl)
				return null;
			return new cl();
		}
		
		/** Обработчик событий загрузки скина */
		private function onLoaderProgress(event:ProgressEvent):void {
			calcTotal();
			var target:LoaderInfo = LoaderInfo(event.target);
			trace("onSkinProgress", target.url, target.bytesLoaded);
		}
		
		private function onLoaderComplete(event:Event):void {
			// отписаться от событий загрузчика
			//trace("onLoaderComplete", event.target);
			var target:LoaderInfo = LoaderInfo(event.target);
			target.removeEventListener(Event.COMPLETE, onLoaderComplete);
			target.removeEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
			target.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
			target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
			//trace("onSkinLoad", target.url, target.bytesTotal);
			// остановить и спрятать загруженные клипы
			var contentMC:MovieClip = MovieClip(target.content);
			stopAllClips(contentMC);
			if (contentMC.parent.parent)
				contentMC.parent.parent.removeChild(contentMC.parent);
			// осталось на один файл меньше
			--m_filesLeft;
			calcTotal();
		}
		
		private function onLoaderError(event:Event):void {
			// при любой ошибке загрузки полностью отказаться от смены скина
			m_skinTarget = m_skinCurrent;
			m_filesLeft = 0;
			m_filesTotal = 0;
			cleanLoaders();
			eventSend(new CGEvent(EVENT_ERROR));
		}
		
		/** Пересчитать загруженный и общий объемы */
		private function calcTotal():void {
			var skinCurrent:CGSkinDescriptor = m_skinDescriptors[m_skinTarget];
			if (!skinCurrent)
				return;
			m_filesRatio = 0.0;
			// пройти по всем требующимся для загрузки файлам и подсчитать текущий процент готовности
			var path:String = skinCurrent.fileFirst();
			while (path) {
				var loader:Loader = m_loaders[path];
				if (loader) {
					var total:Number = loader.contentLoaderInfo.bytesTotal;
					if (total > 0)
						m_filesRatio += (loader.contentLoaderInfo.bytesLoaded / total);
				} else {
					// маловероятно, если скины не переключать до завершения их загрузки
					trace("CRITICAL! Loader not found for " + path);
				}
				path = skinCurrent.fileNext();
			}
			if (m_filesTotal > 0)
				m_filesRatio /= m_filesTotal;
			else
				m_filesRatio = 1.0;
			if (m_filesLeft > 0) {
				// TODO передавать текущее значение прогресса загрузки bytesLoaded:bytesTotal
				eventSend(new CGEvent(EVENT_PROGRESS));
			} else {
				doSkinReady();
			}
		}
		
		/** Обновить скины по завершению загрузки */
		private function doSkinReady():void {
			m_skinCurrent = m_skinTarget;
			updateAll();
			cleanLoaders();
			eventSend(new CGEvent(EVENT_FINISH));
		}
		
		/** Вычистить ненужные загрузчики */
		private function cleanLoaders():void {
			var skinCurrent:CGSkinDescriptor = m_skinDescriptors[m_skinCurrent];
			// вычистить все загрузчики
			do {
				var repeat:Boolean = false;
				for (var key:Object in m_loaders) {
					if (skinCurrent.fileHave(key as String) || skinCurrent.embedHave(key as Class))
						// если данный загрузчик используется текущим скином, не выгружать его
						continue;
					var loader:Loader = m_loaders[key];
					var info:LoaderInfo = loader.contentLoaderInfo;
					info.removeEventListener(Event.COMPLETE, onLoaderComplete);
					info.removeEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
					info.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
					info.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
					stopAllClips(loader.content);
					delete m_loaders[key];
					loader.unloadAndStop(true);
					// такой цикл, чтобы при удалении элементов итерируемого объекта не происходило коллизий
					repeat = true;
					break;
				}
			} while (repeat);
		}
		
		/** Иерархическая остановка всего дерева загруженных клипов */
		private function stopAllClips(parent:DisplayObject):void {
			if (!parent)
				return;
			parent.visible = false;
			if (parent is MovieClip)
				MovieClip(parent).stop();
			if (!(parent is DisplayObjectContainer))
				return;
			var list:Vector.<DisplayObjectContainer> = new <DisplayObjectContainer>[DisplayObjectContainer(parent)];
			while (list.length > 0) {
				var container:DisplayObjectContainer = list.pop();
				for (var i:int = 0, n:int = container.numChildren; i < n; ++i) {
					var child:DisplayObject = container.getChildAt(i);
					child.visible = false;
					if (child is MovieClip)
						MovieClip(child).stop();
					if (child is DisplayObjectContainer)
						list.push(DisplayObjectContainer(child));
				}
			}
		}		
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_idList:Dictionary; // списки обработчиков, связанные с идентификаторами ресурсов
		private var m_listeners:Vector.<Function>; // список простых обработчиков смены скина
		private var m_skinList:Vector.<String>; // список идентификаторов скинов в порядке их добавления
		private var m_skinDescriptors:Dictionary; // список скинов по идентификаторам
		private var m_skinCurrent:String; // идентификатор текущего выбранного скина
		private var m_skinTarget:String; // идентификатор загружаемого скина
		private var m_loaders:Dictionary; // список загруженных ресурсов
		private var m_filesTotal:int; // общее количество ожидаемых файлов
		private var m_filesLeft:int; // количество оставшихеся для загрузки файлов
		private var m_filesRatio:Number; // соотношение загруженного объема
		
		private static var m_instance:CGSkin;
		
	}

}

internal class TSkinLock { }
