package ui.common {
	
	import flash.display.MovieClip;
	
	/**
	 * Элемент скроллируемого списка
	 * 
	 * @version  1.0.5
	 * @author   meps
	 */
	public class CGScrollableItem extends CGInteractive {
		
		public function CGScrollableItem(src:* = null, name:String = null) {
			m_data = null;
			super(src, name);
		}
		
		public function update(data:* = null):void {
			if (m_data) {
				// изменились только данные
				m_data = data;
				onUpdate();
				return;
			}
			// изменилось и состояние
			m_data = data;
			doState();
			onUpdate();
		}
		
		public function clear():void {
			if (!m_data)
				return;
			// изменилось состояние
			m_data = null;
			doState();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			return m_data ? COMMON_STATE : DISABLE_STATE;
		}
		
		override protected function onStateFinish():void {
			var hitMc:MovieClip = objectFind(HIT_ID) as MovieClip;
			if (!hitMc)
				hitMc = clip;
			checkToHit(hitMc);
			super.onStateFinish();
		}
		
		protected function onUpdate():void {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		protected var m_data:*;
		
		private static const COMMON_STATE:String = "common";
		private static const DISABLE_STATE:String = "disable";
		
	}

}