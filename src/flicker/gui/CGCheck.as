package flicker.gui {
	
	import flicker.utils.printClass;
	
	/**
	 * Чекбокс
	 *
	 * @version  1.0.6
	 * @author   meps
	 */
	public class CGCheck extends CGButton {
		
		public function CGCheck(src:* = null, name:String = null, lab:String = null) {
			mSelect = false;
			super(src, name, lab);
		}
		
		/** Флаг включенного состояния чекбокса */
		public function get select():Boolean {
			return mSelect;
		}
		
		public function set select(val:Boolean):void {
			if (mSelect == val)
				return;
			mSelect = val;
			doState();
			onSelect();
			eventSend(new CGEventSelect(CGEventSelect.SELECT, mSelect));
		}
		
		override public function toString():String {
			return printClass(this, "over", "down", "enable", "select");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			return super.doStateValue() +
				"_" +
				(mSelect ? STATE_SELECT : STATE_REGULAR);
		}
		
		override protected function doButtonClick():void {
			select = !select;
			super.doButtonClick();
		}
		
		protected function onSelect():void {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mSelect:Boolean;
		
		private static const STATE_SELECT:String  = "select";
		private static const STATE_REGULAR:String = "regular";
		
	}

}
