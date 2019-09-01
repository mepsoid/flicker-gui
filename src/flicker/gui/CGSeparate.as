package flicker.gui {
	
	import flash.display.MovieClip;
	
	/**
	 * Контейнер для физически разделенных управляемых элементов
	 *
	 * @version  1.0.3
	 * @author   meps
	 */
	public class CGSeparate extends CGContainer {
		
		public function CGSeparate(src:* = null, name:String = null) {
			// используется предок целиком, без выделения вложенного клипа по имени
			mName = name;
			super(src);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onClipParent():void {
			super.onClipParent();
			//trace("CGSeparate::onClipParent", printClass(mParent, "clip"));
			doClipUpdate();
		}
		
		override protected function onClipProcess():void {
			super.onClipProcess();
			//trace("CGSeparate::onClipProcess", printClass(mParent, "clip"));
			if (!doClipUpdate())
				eventSend(new CGEvent(UPDATE));
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private function doClipUpdate():Boolean {
			var oldClip:MovieClip = clip;
			var newClip:MovieClip = mParent ? mParent.clip : null;
			//trace("CGSeparate::update", printClass(oldClip), "-->", printClass(newClip));
			if (oldClip === newClip)
				return false;
			if (oldClip)
				doClipRemove();
			if (newClip)
				doClipAppend(newClip);
			eventSend(new CGEvent(UPDATE));
			return true;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Референсное имя для группы объектов, модифицируемое суффиксами */
		protected var mName:String;
		
	}

}