package ui.common {
	import services.printClass;
	
	/**
	 * Базовое событие элементов интерфейса
	 *
	 * @version  1.0.3
	 * @author   meps
	 */
	public class CGEvent {
		
		public static const OVER:String = "over";
		public static const OUT:String = "out";
		public static const DOWN:String = "down";
		public static const UP:String = "up";
		public static const CLICK:String = "click";
		
		public function CGEvent(type:String) {
			m_type = type;
		}
		
		/** Тип события */
		public function get type():String {
			return m_type;
		}
		
		/** Владелец события */
		public function get target():CGDispatcher {
			return m_target;
		}
		
		public function toString():String {
			return printClass(this, "type");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		internal function targetSet(target:CGDispatcher):void {
			m_target = target;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_type:String;
		private var m_target:CGDispatcher;
		
	}

}
