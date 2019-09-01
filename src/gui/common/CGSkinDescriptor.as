package ui.common {
	
	import flash.utils.Dictionary;
	
	/**
	 * Дескриптор скина, соответствие идентификаторов классам и список используемых файлов
	 * 
	 * @version  1.1.2
	 * @author   meps
	 */
	public class CGSkinDescriptor {
		
		/** @private */
		public function CGSkinDescriptor(skinId:String) {
			m_id = skinId;
			m_embeds = new Vector.<Class>();
			m_files = new Vector.<String>();
			m_resources = new Dictionary();
		}
		
		/** Идентификатор скина */
		public function get id():String {
			return m_id;
		}
		
		/** Добавить в скин вкомпилированный класс с ресурсами; второй параметр
		 * описывает все идентификаторы находящихся в данном классе ресурсов */
		public function embedSource(embed:Class, bindedList:Vector.<String> = null):void {
			// TODO связать с классом идентификаторы находящихся в нем ресурсов
			if (embedHave(embed))
				return;
			m_embeds.push(embed);
		}
		
		/** Проверить наличие класса с ресурсами */
		public function embedHave(embed:Class):Boolean {
			return m_embeds.indexOf(embed) >= 0;
		}
		
		/** Начать итерацию по классам с ресурсами */
		public function embedFirst():Class {
			m_embedIterator = 1;
			if (m_embeds.length == 0)
				return null;
			return m_embeds[0];
		}
		
		/** Следующий элемент в списке классов с ресурсами */
		public function embedNext():Class {
			if (m_embedIterator >= m_embeds.length)
				return null;
			return m_embeds[m_embedIterator++];
		}
		
		/** Добавить в скин путь к файлу с ресурсами; второй параметр описывает
		 * все идентификаторя находящихся в данном файле ресурсов */
		public function fileSource(path:String, bindedList:Vector.<String> = null):void {
			// TODO связать с файлом идентификаторы находящихся в нем ресурсов
			if (fileHave(path))
				return;
			m_files.push(path);
		}
		
		/** Проверить наличие файла по пути */
		public function fileHave(path:String):Boolean {
			return m_files.indexOf(path) >= 0;
		}
		
		/** Начать итерацию по именам файлов */
		public function fileFirst():String {
			m_fileIterator = 1;
			if (m_files.length == 0)
				return null;
			return m_files[0];
		}
		
		/** Следующий элемент в списке имен файлов */
		public function fileNext():String {
			if (m_fileIterator >= m_files.length)
				return null;
			return m_files[m_fileIterator++];
		}
		
		/** Связать идентификатор с именем класса ресурса; для совпадающих
		 * идентификатора и имени класса вызов метода бессмысленен -- связывание
		 * по такому правилу действует по умолчанию */
		public function resourceBind(resourceId:String, className:String = null):void {
			if (className)
				m_resources[resourceId] = className;
			else
				m_resources[resourceId] = resourceId;
		}
		
		/** Получить имя класса ресурса по идентификатору */
		public function resourceGet(resourceId:String):String {
			if (!m_resources.hasOwnProperty(resourceId)) {
				//CONFIG::debug { trace("!", "Unbinded resource at CGSkin.resourceGet(" + resourceId + ")"); }
				// по умолчанию возвращать идентификатор вместо связанного с ним биндинга
				return resourceId;
			}
			return m_resources[resourceId];
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_id:String;
		private var m_embeds:Vector.<Class>;
		private var m_embedIterator:int = 0;
		private var m_files:Vector.<String>;
		private var m_fileIterator:int = 0;
		private var m_resources:Dictionary;
		
	}

}