package ui.common {
	
	/**
	 * Элемент скроллируемого списка
	 * 
	 * @version  1.0.2
	 * @author   meps
	 */
	public class CGScrollableItem extends CGInteractive {
		
		public function CGScrollableItem(src:* = null, name:String = null) {
			m_enable = false;
			super(src, name);
		}
		
		public function update(data:* = null):void {
			m_data = data;
			if (m_enable) {
				onUpdate();
				return;
			}
			m_enable = true;
			doState();
			onUpdate();
		}
		
		public function clear():void {
			if (!m_enable)
				return;
			m_enable = false;
			doState();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			return m_enable ? COMMON_STATE : DISABLE_STATE;
		}
		
		protected function onUpdate():void {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		protected var m_enable:Boolean;
		protected var m_data:*;
		
		private static const COMMON_STATE:String = "common";
		private static const DISABLE_STATE:String = "disable";
		
	}

}