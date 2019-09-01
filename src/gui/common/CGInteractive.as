package framework.gui {
	
	import app.gui.common.richtext.CGProtoWithRichText;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import framework.utils.printClass;
	
	/**
	 * Класс интерактивного элемента интерфейса
	 * 
	 * @version  1.0.10
	 * @author   meps
	 */
	public class CGInteractive extends CGProtoWithRichText {
		
		public function CGInteractive(src:* = null, name:String = null) {
			mOver = false;
			mDown = false;
			super(src, name);
		}
		
		/** Нахождение курсора над элементом */
		public function get over():Boolean {
			return mOver;
		}
		
		/** Нажатие на элемент */
		public function get down():Boolean {
			return mDown;
		}
		
		/** Тултип элемента */
		public function get tip():CGTip {
			return mTip;
		}
		
		public function set tip(val:CGTip):void {
			mTip = val;
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
			mc.addEventListener(MouseEvent.ROLL_OVER, onClipMouse);
			mc.addEventListener(MouseEvent.ROLL_OUT, onClipMouse);
			mc.addEventListener(MouseEvent.MOUSE_DOWN, onClipMouse);
			mc.addEventListener(MouseEvent.MOUSE_UP, onClipMouse);
			mc.addEventListener(Event.ADDED_TO_STAGE, onClipAdded);
			mc.addEventListener(Event.REMOVED_FROM_STAGE, onClipRemoved);
		}
		
		override protected function onClipRemove(mc:MovieClip):void {
			mc.hitArea = null;
			mc.removeEventListener(MouseEvent.ROLL_OVER, onClipMouse);
			mc.removeEventListener(MouseEvent.ROLL_OUT, onClipMouse);
			mc.removeEventListener(MouseEvent.MOUSE_DOWN, onClipMouse);
			mc.removeEventListener(MouseEvent.MOUSE_UP, onClipMouse);
			mc.removeEventListener(Event.ADDED_TO_STAGE, onClipAdded);
			mc.removeEventListener(Event.REMOVED_FROM_STAGE, onClipRemoved);
			super.onClipRemove(mc);
		}
		
		override protected function onDestroy():void {
			if (mTip) {
				mTip.destroy();
				mTip = null;
			}
			if (clip) {
				var mc:MovieClip = objectFind(HIT_ID) as MovieClip;
				if (!mc)
					mc = clip;
				mc.removeEventListener(MouseEvent.ROLL_OVER, onClipMouse);
				mc.removeEventListener(MouseEvent.ROLL_OUT, onClipMouse);
				mc.removeEventListener(MouseEvent.MOUSE_DOWN, onClipMouse);
				mc.removeEventListener(MouseEvent.MOUSE_UP, onClipMouse);
				mc.removeEventListener(Event.ADDED_TO_STAGE, onClipAdded);
				mc.removeEventListener(Event.REMOVED_FROM_STAGE, onClipRemoved);
			}
			super.onDestroy();
		}
		
		protected function onClipMouse(event:MouseEvent):void {
			if (event.type == MouseEvent.ROLL_OVER) {
				mOver = true;
				doState();
				eventSend(EVENT_OVER);
				if (mTip)
					mTip.show();
			} else if (event.type == MouseEvent.ROLL_OUT) {
				mOver = false;
				mDown = false;
				doState();
				eventSend(EVENT_OUT);
				if (mTip)
					mTip.hide();
			} else if (event.type == MouseEvent.MOUSE_DOWN) {
				mDown = true;
				doState();
				eventSend(EVENT_DOWN);
			} else if (event.type == MouseEvent.MOUSE_UP) {
				mDown = false;
				doState();
				eventSend(EVENT_UP);
			}
		}
		
		/** Наведена ли мышь на кнопку */
		protected function checkToHit(mc:MovieClip):void {
			if (mc && mc.stage) {
				var rect:Rectangle = mc.getRect(mc.stage);
				var mouseX:Number = mc.stage.mouseX;
				var mouseY:Number = mc.stage.mouseY;
				if (rect.contains(mouseX, mouseY)) {
					mOver = mc.hitTestPoint(mouseX, mouseY, true);
				} else {
					mOver = false;
				}
			} else {
				mOver = false;
			}
		}
		
		private function onClipAdded(event:Event):void {
			var hitMc:MovieClip = objectFind(HIT_ID) as MovieClip;
			if (!hitMc)
				hitMc = clip;
			checkToHit(hitMc);
		}
		
		private function onClipRemoved(event:Event):void {
			mOver = false;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		protected var mOver:Boolean;
		protected var mDown:Boolean;
		protected var mTip:CGTip;
		
		private const EVENT_OVER:CGEvent = new CGEvent(CGEvent.OVER);
		private const EVENT_OUT:CGEvent = new CGEvent(CGEvent.OUT);
		private const EVENT_DOWN:CGEvent = new CGEvent(CGEvent.DOWN);
		private const EVENT_UP:CGEvent = new CGEvent(CGEvent.UP);
		
		protected static const HIT_ID:String = ".hit";
		
	}

}
