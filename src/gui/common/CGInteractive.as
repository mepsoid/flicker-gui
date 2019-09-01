package ui.common {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	import services.printClass;
	
	/**
	 * Класс интерактивного элемента интерфейса
	 * 
	 * @version  1.0.5
	 * @author   meps
	 */
	public class CGInteractive extends CGLabel {
		
		public function CGInteractive(src:* = null, name:String = null) {
			//log.write("#", "CGInteractive::constructor", src, name);
			m_over = false;
			m_down = false;
			super(src, name);
		}
		
		/** Нахождение курсора над элементом */
		public function get over():Boolean {
			return m_over;
		}
		
		/** Нажатие на элемент */
		public function get down():Boolean {
			return m_down;
		}
		
		/** Тултип элемента */
		public function get tip():CGTip {
			return m_tip;
		}
		
		public function set tip(val:CGTip):void {
			m_tip = val;
		}
		
		override public function toString():String {
			return printClass(this, "over", "down");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			var hit:MovieClip = objectFind(HIT_ID) as MovieClip;
			if (hit)
				mc.hitArea = hit;
			else
				mc.hitArea = null;
			mc.addEventListener(MouseEvent.ROLL_OVER, onClipMouse, false, 0, true);
			mc.addEventListener(MouseEvent.ROLL_OUT, onClipMouse, false, 0, true);
			mc.addEventListener(MouseEvent.MOUSE_DOWN, onClipMouse, false, 0, true);
			mc.addEventListener(MouseEvent.MOUSE_UP, onClipMouse, false, 0, true);
		}
		
		override protected function onClipRemove(mc:MovieClip):void {
			mc.hitArea = null;
			mc.removeEventListener(MouseEvent.ROLL_OVER, onClipMouse);
			mc.removeEventListener(MouseEvent.ROLL_OUT, onClipMouse);
			mc.removeEventListener(MouseEvent.MOUSE_DOWN, onClipMouse);
			mc.removeEventListener(MouseEvent.MOUSE_UP, onClipMouse);
			super.onClipRemove(mc);
		}
		
		override protected function onDestroy():void {
			if (m_tip) {
				m_tip.destroy();
				m_tip = null;
			}
			if (clip) {
				clip.removeEventListener(MouseEvent.ROLL_OVER, onClipMouse);
				clip.removeEventListener(MouseEvent.ROLL_OUT, onClipMouse);
				clip.removeEventListener(MouseEvent.MOUSE_DOWN, onClipMouse);
				clip.removeEventListener(MouseEvent.MOUSE_UP, onClipMouse);
			}
			super.onDestroy();
		}
		
		protected function onClipMouse(event:MouseEvent):void {
			if (event.type == MouseEvent.ROLL_OVER) {
				m_over = true;
				doState();
				eventSend(new CGEvent(CGEvent.OVER));
				if (m_tip)
					m_tip.show();
			} else if (event.type == MouseEvent.ROLL_OUT) {
				m_over = false;
				m_down = false;
				doState();
				eventSend(new CGEvent(CGEvent.OUT));
				if (m_tip)
					m_tip.hide();
			} else if (event.type == MouseEvent.MOUSE_DOWN) {
				m_down = true;
				doState();
				eventSend(new CGEvent(CGEvent.DOWN));
			} else if (event.type == MouseEvent.MOUSE_UP) {
				m_down = false;
				doState();
				eventSend(new CGEvent(CGEvent.UP));
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		protected var m_over:Boolean;
		protected var m_down:Boolean;
		protected var m_tip:CGTip;
		
		protected static const HIT_ID:String = ".hit";
		
	}

}
