package ui.common {
	
	import services.printClass;
	
	/**
	 * Событие смены состояния элемента интерфейса
	 *
	 * @version  1.0.3
	 * @author   meps
	 */
	public class CGEventState extends CGEvent {
		
		/** Тип события смены состояния */
		public static const STATE:String = "state_state";
		
		/** Тип события начала перехода при смене состояния */
		public static const START:String = "state_start";
		
		/** Тип события окончания перехода при смене состояния */
		public static const FINISH:String = "state_finish";
		
		/** Прохождение метки при анимации */
		public static const LABEL:String = "state_label";
		
		public function CGEventState(type:String, state:String) {
			m_state = state;
			super(type);
		}
		
		/** Установленное состояние элемента */
		public function get state():String {
			return m_state;
		}
		
		override public function toString():String {
			return printClass(this, "type", "state");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_state:String;
		
	}
}