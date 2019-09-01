package ui.common {
	
	import services.printClass;
	
	/**
	 * Чекбокс
	 * 
	 * @version  1.0.5
	 * @author   meps
	 */
	public class CGCheck extends CGButton {
		
		public function CGCheck(src:* = null, name:String = null, lab:String = null) {
			m_select = false;
			super(src, name, lab);
		}
		
		/** Флаг включенного состояния чекбокса */
		public function get select():Boolean {
			return m_select;
		}
		
		public function set select(val:Boolean):void {
			if (m_select == val)
				return;
			m_select = val;
			doState();
			onSelect();
			eventSend(new CGEventSelect(CGEventSelect.SELECT, m_select));
		}
		
		override public function toString():String {
			return printClass(this, "over", "down", "enable", "select");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			return super.doStateValue() +
				"_" +
				(m_select ? STATE_SELECT : STATE_REGULAR);
		}
		
		override protected function doButtonClick():void {
			select = !select;
			super.doButtonClick();
		}
		
		protected function onSelect():void {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_select:Boolean;
		
		private static const STATE_SELECT:String  = "select";
		private static const STATE_REGULAR:String = "regular";
		
	}

}
