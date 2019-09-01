package framework.gui {
	
	import flash.utils.Dictionary;
	
	/**
	 * Дескриптор скина, соответствие идентификаторов классам и список используемых файлов
	 * 
	 * @version  1.1.3
	 * @author   meps
	 */
	public class CGSkinDescriptor {
		
		/** @private */
		public function CGSkinDescriptor(skinId:String) {
			mId = skinId;
			mEmbeds = new Vector.<Class>();
			mFiles = new Vector.<String>();
			mResources = new Dictionary();
		}
		
		/** Идентификатор скина */
		public function get id():String {
			return mId;
		}
		
		/** Добавить в скин вкомпилированный класс с ресурсами; второй параметр
		 * описывает все идентификаторы находящихся в данном классе ресурсов */
		public function embedSource(embed:Class, bindedList:Vector.<String> = null):void {
			// TODO связать с классом идентификаторы находящихся в нем ресурсов
			if (embedHave(embed))
				return;
			mEmbeds.push(embed);
		}
		
		/** Проверить наличие класса с ресурсами */
		public function embedHave(embed:Class):Boolean {
			return mEmbeds.indexOf(embed) >= 0;
		}
		
		/** Начать итерацию по классам с ресурсами */
		public function embedFirst():Class {
			mEmbedIterator = 1;
			if (mEmbeds.length == 0)
				return null;
			return mEmbeds[0];
		}
		
		/** Следующий элемент в списке классов с ресурсами */
		public function embedNext():Class {
			if (mEmbedIterator >= mEmbeds.length)
				return null;
			return mEmbeds[mEmbedIterator++];
		}
		
		/** Добавить в скин путь к файлу с ресурсами; второй параметр описывает
		 * все идентификаторя находящихся в данном файле ресурсов */
		public function fileSource(path:String, bindedList:Vector.<String> = null):void {
			// TODO связать с файлом идентификаторы находящихся в нем ресурсов
			if (fileHave(path))
				return;
			mFiles.push(path);
		}
		
		/** Проверить наличие файла по пути */
		public function fileHave(path:String):Boolean {
			return mFiles.indexOf(path) >= 0;
		}
		
		/** Начать итерацию по именам файлов */
		public function fileFirst():String {
			mFileIterator = 1;
			if (mFiles.length == 0)
				return null;
			return mFiles[0];
		}
		
		/** Следующий элемент в списке имен файлов */
		public function fileNext():String {
			if (mFileIterator >= mFiles.length)
				return null;
			return mFiles[mFileIterator++];
		}
		
		/** Связать идентификатор с именем класса ресурса; для совпадающих
		 * идентификатора и имени класса вызов метода бессмысленен -- связывание
		 * по такому правилу действует по умолчанию */
		public function resourceBind(resourceId:String, className:String = null):void {
			if (className)
				mResources[resourceId] = className;
			else
				mResources[resourceId] = resourceId;
		}
		
		/** Получить имя класса ресурса по идентификатору */
		public function resourceGet(resourceId:String):String {
			if (!mResources.hasOwnProperty(resourceId)) {
				//CONFIG::debug { trace("!", "Unbinded resource at CGSkin.resourceGet(" + resourceId + ")"); }
				// по умолчанию возвращать идентификатор вместо связанного с ним биндинга
				return resourceId;
			}
			return mResources[resourceId];
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mId:String;
		private var mEmbeds:Vector.<Class>;
		private var mEmbedIterator:int = 0;
		private var mFiles:Vector.<String>;
		private var mFileIterator:int = 0;
		private var mResources:Dictionary;
		
	}

}
