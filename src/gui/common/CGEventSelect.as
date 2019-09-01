package ui.common {
	
	import services.printClass;
	
	/**
	 * Событие выбора значения из списка
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public class CGEventSelect extends CGEvent {
		
		/** Тип события выбора значения */
		public static const SELECT:String = "select_select";
		
		/** Тип события изменения значения */
		public static const CHANGE:String = "select_change";
		
		public function CGEventSelect(type:String, value:*) {
			m_value = value;
			super(type);
		}
		
		/** Выбранное значение */
		public function get value():* {
			return m_value;
		}
		
		override public function toString():String {
			return printClass(this, "type", "value");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_value:*;
		
	}
}