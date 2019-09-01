package ui.common {
	
	import services.printClass;
	
	/**
	 * Событие переключения состояния
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public class CGEventSwitch extends CGEvent {
		
		/** Событие переключения видимости элемента */
		public static const SHOW:String = "switch_show";
		
		/** Событие переключения активного состояния */
		public static const SELECT:String = "switch_select";
		
		/** Событие переключения активного состояния */
		public static const CHANGE:String = "switch_change";
		
		public function CGEventSwitch(type:String, active:Boolean) {
			m_active = active;
			super(type);
		}
		
		/** Текущая активность состояния */
		public function get active():Boolean {
			return m_active;
		}
		
		override public function toString():String {
			return printClass(this, "type", "active");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_active:Boolean;
		
	}
}