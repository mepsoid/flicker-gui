package ui.common {
	
	import flash.display.MovieClip;
	
	/**
	 * Контейнер для физически разделенных управляемых элементов
	 * 
	 * @version  1.0.2
	 * @author   meps
	 */
	public class CGSeparate extends CGContainer {
		
		public function CGSeparate(src:* = null, name:String = null) {
			// используется предок целиком, без выделения вложенного клипа по имени
			m_name = name;
			super(src);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onClipParent():void {
			super.onClipParent();
			//trace("CGSeparate::onClipParent", printClass(m_parent, "clip"));
			doClipUpdate();
		}
		
		override protected function onClipProcess():void {
			super.onClipProcess();
			//trace("CGSeparate::onClipProcess", printClass(m_parent, "clip"));
			if (!doClipUpdate())
				eventSend(new CGEvent(UPDATE));
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private function doClipUpdate():Boolean {
			var oldClip:MovieClip = clip;
			var newClip:MovieClip = m_parent ? m_parent.clip : null;
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
		protected var m_name:String;
		
	}

}