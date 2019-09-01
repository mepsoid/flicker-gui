package framework.gui {
	
	import flash.display.MovieClip;
	
	/**
	 * Элемент скроллируемого списка
	 * 
	 * @version  1.0.5
	 * @author   meps
	 */
	public class CGScrollableItem extends CGInteractive {
		
		public function CGScrollableItem(src:* = null, name:String = null) {
			mData = null;
			super(src, name);
		}
		
		public function update(data:* = null):void {
			if (mData) {
				// изменились только данные
				mData = data;
				onUpdate();
				return;
			}
			// изменилось и состояние
			mData = data;
			doState();
			onUpdate();
		}
		
		public function clear():void {
			if (!mData)
				return;
			// изменилось состояние
			mData = null;
			doState();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			return mData ? COMMON_STATE : DISABLE_STATE;
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
		
		protected var mData:*;
		
		private static const COMMON_STATE:String = "common";
		private static const DISABLE_STATE:String = "disable";
		
	}

}
