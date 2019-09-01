package flicker.gui {
	
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
	 * @version  1.2.16
	 * @author   meps
	 */
	public class CGSkin extends CGDispatcher {
		
		public static const EVENT_START:String = "skin_change_start"; // событие начала смены скина
		public static const EVENT_PROGRESS:String = "skin_change_progress"; // событие процесса загрузки и смены скина
		public static const EVENT_FINISH:String = "skin_change_finish"; // событие завершения смены скина
		public static const EVENT_ERROR:String = "skin_change_error"; // событие ошибки при смене скина
		
		public static function get instance():CGSkin {
			if (!mInstance)
				mInstance = new CGSkin(new TSkinLock());
			return mInstance;
		}
		
		public function CGSkin(lock:TSkinLock) {
			if (!lock)
				throw new Error("Use CGSkin.instance for access!");
			mIdList = new Dictionary();
			mListeners = new Vector.<Function>();
			mSkinList = new Vector.<String>();
			mSkinDescriptors = new Dictionary();
			mLoaders = new Dictionary();
		}
		
		/** Подписаться на обновление ресурса */
		public function connect(resourceId:String, target:IGSkinnable):void {
			var targets:Dictionary;
			if (mIdList.hasOwnProperty(resourceId)) {
				targets = mIdList[resourceId];
				if (target in targets)
					// подписывать только отсутствующий обработчик
					return;
			} else {
				targets = new Dictionary(true);
				mIdList[resourceId] = targets;
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
			if (!mIdList.hasOwnProperty(resourceId))
				return;
			var targets:Dictionary = mIdList[resourceId];
			delete targets[target];
		}
		
		/** Подписаться на смену скина */
		public function listen(listener:Function):void {
			if (mListeners.indexOf(listener) >= 0)
				return;
			mListeners.push(listener);
		}
		
		/** Отказаться от подписки на смену скина */
		public function unlisten(listener:Function):void {
			var index:int = mListeners.indexOf(listener);
			if (index < 0)
				return;
			var len:int = mListeners.length - 1;
			mListeners[index] = mListeners[len];
			mListeners.length = len;
		}
		
		/** Получить дескриптор скина по идентификатору; если дескриптора еще не
		 * существует, он создается */
		public function skinGet(id:String):CGSkinDescriptor {
			if (id in mSkinDescriptors)
				return mSkinDescriptors[id];
			var skin:CGSkinDescriptor = new CGSkinDescriptor(id);
			mSkinDescriptors[id] = skin;
			mSkinList.push(id);
			return skin;
		}
		
		/** Список идентификаторов всех добавленных скинов */
		public function get skinList():Vector.<String> {
			return mSkinList.concat();
		}
		
		/** Текущий скин */
		public function get skinSelect():String {
			return mSkinCurrent;
		}
		
		public function set skinSelect(id:String):void {
			var loader:Loader;
			if (!(id in mSkinDescriptors) || id == mSkinCurrent || id == mSkinTarget || mFilesLeft > 0)
				// желаемого скина нет, выбирается он же, либо загрузка предыдущего еще не окончена
				return;
			mSkinTarget = id;
			// событие начала обновления скина
			eventSend(new CGEvent(EVENT_START));
			// набрать в очередь загрузки отсутствующие файлы ресурсов
			var currentSkin:CGSkinDescriptor = mSkinDescriptors[mSkinTarget];
			mFilesTotal = 0;
			// поставить на загрузку внешние файлы
			var path:String = currentSkin.fileFirst();
			while (path) {
				if (!(path in mLoaders)) {
					++mFilesTotal;
					// такого загрузчика еще нет в очереди
					loader = new Loader(); 
					mLoaders[path] = loader;
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
				if (!(embed in mLoaders))
					++mFilesTotal;
				embed = currentSkin.embedNext();
			}
			mFilesLeft = mFilesTotal;
			// загрузить классы с ресурсами
			embed = currentSkin.embedFirst();
			while (embed) {
				if (!(embed in mLoaders)) {
					// такой ресурс еще не был загружен и создан
					loader = new Loader();
					mLoaders[embed] = loader;
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
					loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
					loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
					loader.loadBytes(new embed(), new LoaderContext(false, new ApplicationDomain()));
				}
				embed = currentSkin.embedNext();
			}
			if (mFilesLeft == 0)
				// внешних файлов нет
				doSkinReady();
		}
		
		/** Соотношение загруженного объема */
		public function get ratio():Number {
			return mFilesRatio;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обновить элементы интерфейса, связанные с заданным ресурсом */
		private function update(resourceId:String):void {
			if (!mIdList.hasOwnProperty(resourceId))
				return;
			var targets:Dictionary = mIdList[resourceId];
			for (var target:Object in targets) {
				var data:* = resourceCreate(resourceId);
				// null является допустимым значением в качестве данных запрошенного ресурса
				IGSkinnable(target).skinUpdate(resourceId, data);
			}
		}
		
		/** Обновить все элементы интерфейса */
		private function updateAll():void {
			for (var resourceId:String in mIdList)
				update(resourceId);
			// сообщить всем подписчикам об обновлении скина
			for each (var func:Function in mListeners)
				func();
		}
		
		/** Создать ресурс по идентификатору */
		private function resourceCreate(resourceId:String):* {
			var cl:Class, key:Object, loader:Loader, domain:ApplicationDomain;
			var currentSkin:CGSkinDescriptor = mSkinDescriptors[mSkinCurrent];
			if (!currentSkin) {
				// еще не подгружен ни один скин, воссоздавать ресурсы из текущего домена
				try {
					// попробовать создать ресурс, используя идентификатор в качестве имени класса
					cl = getDefinitionByName(resourceId) as Class;
				} catch (error:Error) {
					CONFIG::debug { trace(error.message); }
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
				for (key in mLoaders)
					if (currentSkin.fileHave(key as String) || currentSkin.embedHave(key as Class)) {
						// попробовать использовать данный файл, если он перечислен в текущем скине как источник ресурсов
						loader = mLoaders[key];
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
					for (key in mLoaders)
						if (!currentSkin.fileHave(key as String) && !currentSkin.embedHave(key as Class)) {
							// использовать файлы чужого скина, которые изначально были проигнорированы
							loader = mLoaders[key];
							domain = loader.contentLoaderInfo.applicationDomain;
							if (domain.hasDefinition(className)) {
								cl = domain.getDefinition(className) as Class; 
								break; // прервать поиск, поскольку нам достаточно первого найденного класса
							}
						}
			} catch (error:Error) {
				CONFIG::debug { trace(error.message, className); }
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
		}
		
		private function onLoaderComplete(event:Event):void {
			// отписаться от событий загрузчика
			var target:LoaderInfo = LoaderInfo(event.target);
			target.removeEventListener(Event.COMPLETE, onLoaderComplete);
			target.removeEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
			target.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
			target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
			// остановить и спрятать загруженные клипы
			var contentMC:MovieClip = MovieClip(target.content);
			stopAllClips(contentMC);
			if (contentMC.parent.parent)
				contentMC.parent.parent.removeChild(contentMC.parent);
			// осталось на один файл меньше
			--mFilesLeft;
			calcTotal();
		}
		
		private function onLoaderError(event:Event):void {
			// при любой ошибке загрузки полностью отказаться от смены скина
			mSkinTarget = mSkinCurrent;
			mFilesLeft = 0;
			mFilesTotal = 0;
			cleanLoaders();
			eventSend(new CGEvent(EVENT_ERROR));
		}
		
		/** Пересчитать загруженный и общий объемы */
		private function calcTotal():void {
			var skinCurrent:CGSkinDescriptor = mSkinDescriptors[mSkinTarget];
			if (!skinCurrent)
				return;
			mFilesRatio = 0.0;
			// пройти по всем требующимся для загрузки файлам и подсчитать текущий процент готовности
			var path:String = skinCurrent.fileFirst();
			while (path) {
				var loader:Loader = mLoaders[path];
				if (loader) {
					var total:Number = loader.contentLoaderInfo.bytesTotal;
					if (total > 0)
						mFilesRatio += (loader.contentLoaderInfo.bytesLoaded / total);
				} else {
					// маловероятно, если скины не переключать до завершения их загрузки
					CONFIG::debug { trace("CRITICAL! Loader not found for " + path); }
				}
				path = skinCurrent.fileNext();
			}
			if (mFilesTotal > 0)
				mFilesRatio /= mFilesTotal;
			else
				mFilesRatio = 1.0;
			if (mFilesLeft > 0) {
				// TODO передавать текущее значение прогресса загрузки bytesLoaded:bytesTotal
				eventSend(new CGEvent(EVENT_PROGRESS));
			} else {
				doSkinReady();
			}
		}
		
		/** Обновить скины по завершению загрузки */
		private function doSkinReady():void {
			mSkinCurrent = mSkinTarget;
			updateAll();
			cleanLoaders();
			eventSend(new CGEvent(EVENT_FINISH));
		}
		
		/** Вычистить ненужные загрузчики */
		private function cleanLoaders():void {
			var skinCurrent:CGSkinDescriptor = mSkinDescriptors[mSkinCurrent];
			// вычистить все загрузчики
			do {
				var repeat:Boolean = false;
				for (var key:Object in mLoaders) {
					if (skinCurrent.fileHave(key as String) || skinCurrent.embedHave(key as Class))
						// если данный загрузчик используется текущим скином, не выгружать его
						continue;
					var loader:Loader = mLoaders[key];
					var info:LoaderInfo = loader.contentLoaderInfo;
					info.removeEventListener(Event.COMPLETE, onLoaderComplete);
					info.removeEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
					info.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError);
					info.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
					stopAllClips(loader.content);
					delete mLoaders[key];
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
		
		private var mIdList:Dictionary; // списки обработчиков, связанные с идентификаторами ресурсов
		private var mListeners:Vector.<Function>; // список простых обработчиков смены скина
		private var mSkinList:Vector.<String>; // список идентификаторов скинов в порядке их добавления
		private var mSkinDescriptors:Dictionary; // список скинов по идентификаторам
		private var mSkinCurrent:String; // идентификатор текущего выбранного скина
		private var mSkinTarget:String; // идентификатор загружаемого скина
		private var mLoaders:Dictionary; // список загруженных ресурсов
		private var mFilesTotal:int; // общее количество ожидаемых файлов
		private var mFilesLeft:int; // количество оставшихеся для загрузки файлов
		private var mFilesRatio:Number; // соотношение загруженного объема
		
		private static var mInstance:CGSkin;
		
	}

}

internal class TSkinLock { }
