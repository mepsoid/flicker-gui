package services {
	
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * Кеширование указателей на объекты с целью их точного перечисления
	 * (замена прямого доступа к внутренним указателям). Из-за невозможности
	 * распечатки указателя на объект невозможно их точно разделять при выводе
	 * в лог: требуется либо запоминать указатели с целью дальнейшего их
	 * разделения через сравнения, либо вводить собственную систему
	 * идентификации экземпляров, либо, зная внутреннюю природу отдельных
	 * элементов (например DisplayObject.name).
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public class CObjectEnumerator {
		
		public static function get instance():CObjectEnumerator {
			if (!m_instance)
				m_instance = new CObjectEnumerator(new TObjectEnumeratorLock());
			return m_instance;
		}
		
		public function CObjectEnumerator(lock:TObjectEnumeratorLock) {
			if (!lock)
				throw new Error("Use CObjectEnumerator.instance for access!");
			m_types = new Dictionary();
		}
		
		/** Зарегистрировать объект и получить его порядковый номер */
		public function check(object:*):int {
			var type:Class = getDefinitionByName(getQualifiedClassName(object)) as Class;
			var group:TObjectGroup = m_types[type];
			if (!group) {
				group = new TObjectGroup();
				m_types[type] = group;
			}
			return group.check(object);
		}
		
		/** Проверить наличие зарегистрированного объекта, но не регистрировать его */
		public function have(object:*):Boolean {
			var type:Class = getDefinitionByName(getQualifiedClassName(object)) as Class;
			var group:TObjectGroup = m_types[type];
			if (!group)
				return false;
			return group.have(object);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_types:Dictionary;
		
		static private var m_instance:CObjectEnumerator;
		
	}

}

import flash.utils.Dictionary;

internal class TObjectGroup {
	
	public function TObjectGroup() {
		m_count = 0;
		m_dict = new Dictionary(true);
	}
	
	public function check(object:*):int {
		var enum:int = m_dict[object];
		if (enum)
			return enum;
		++m_count;
		m_dict[object] = m_count;
		return m_count;
	}
	
	public function have(object:*):Boolean {
		return m_dict.hasOwnProperty(object);
	}
	
	private var m_count:int;
	private var m_dict:Dictionary;
	
}

internal class TObjectEnumeratorLock {
}
