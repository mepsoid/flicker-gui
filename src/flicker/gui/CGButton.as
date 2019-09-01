package flicker.gui {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flicker.utils.printClass;

	/**
	 * Кнопка для графического интерфейса
	 * 
	 * @version  1.2.20
	 * @author   meps
	 */
	public class CGButton extends CGInteractive {
		
		public function CGButton(src:* = null, name:String = null, lab:String = null) {
			mEnable = true;
			mPress = false;
			mTimeWait = WAIT_DEFAULT;
			mTimeRate = RATE_DEFAULT;
			super(src, name);
			if (lab)
				label = lab;
		}
		
		/** Доступность кнопки для взаимодействия с ней */
		public function get enable():Boolean { return mEnable; }
		
		public function set enable(val:Boolean):void {
			if (mEnable == val)
				return;
			mEnable = val;
			doState();
			// обновить статус области ввода
			var hitMc:MovieClip = objectFind(HIT_ID) as MovieClip;
			if (!hitMc)
				hitMc = clip;
			if (hitMc)
				hitMc.buttonMode = mEnable;
			if (!mEnable) {
				// неактивная кнопка не генерирует автонажатий
				mRepeat = false;
				if (mTimer)
					mTimer.stop();
			}
		}
		
		/** Стандартный ярлык кнопки */
		public function get label():String { return textGet(LABEL_ID); }
		
		public function set label(val:String):void { textSet(val, LABEL_ID); }
		
		/** Стандартная иконка кнопки */
		public function get icon():String { return iconGet(ICON_ID); }
		
		public function set icon(val:String):void { iconSet(val, ICON_ID); }
		
		/** Время ожидания до автонажатий (мс) */
		public function get delayWait():int { return mTimeWait; }
		
		public function set delayWait(val:int):void {
			if (val < 0)
				return;
			mTimeWait = val;
			if (val > 0)
				createTimer();
		}
		
		/** Интервал между автонажатиями (мс) */
		public function get delayRate():int {
			return mTimeRate;
		}
		
		public function set delayRate(val:int):void {
			if (val <= 0)
				return;
			mTimeRate = val;
			createTimer();
		}
		
		override public function toString():String {
			return printClass(this, "over", "down", "enable");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			var hitMc:MovieClip = objectFind(HIT_ID) as MovieClip;
			if (!hitMc)
				hitMc = mc;
			checkToHit(hitMc);
			hitMc.buttonMode = mEnable;
			mc.tabEnabled = false;
			//hitMc.mouseChildren = false;
		}
		
		override protected function onClipRemove(mc:MovieClip):void {
			//var hitMc:MovieClip = objectFind(HIT_ID) as MovieClip;
			//if (!hitMc)
				//hitMc = mc;
			mOver = false;
			mDown = false;
			mPress = false;
			if (mTimer)
				mTimer.stop();
			//hitMc.buttonMode = false;
			//hitMc.mouseChildren = true;
			super.onClipRemove(mc);
		}
		
		override protected function onClipMouse(event:MouseEvent):void {
			super.onClipMouse(event);
			if (event.type == MouseEvent.ROLL_OUT) {
				mPress = false;
				if (mTimer)
					mTimer.stop();
			} else if (event.type == MouseEvent.MOUSE_DOWN) {
				mPress = mOver && mEnable;
				mRepeat = false;
				if (mPress && mTimeWait) {
					mTimer.delay = mTimeWait;
					mTimer.start();
				}
				event.stopImmediatePropagation();
			} else if (event.type == MouseEvent.MOUSE_UP) {
				if (mPress && mEnable) {
					if (mTimer)
						mTimer.stop();
					if (!mRepeat || mTimeWait == 0)
						// если еще не было автонажатий или они не используются, при отпускании провести нажатие
						doButtonClick();
					event.stopImmediatePropagation();
				}
				mPress = false;
			}
		}
		
		override protected function doStateValue():String {
			if (mEnable)
				return (mOver ? OVER_STATE : OUT_STATE) + "_" + (mDown ? DOWN_STATE : UP_STATE);
			return DISABLE_STATE;
		}
		
		override protected function onDestroy():void {
			if (mTimer) {
				mTimer.stop();
				mTimer.removeEventListener(TimerEvent.TIMER, onTimer);
				mTimer = null;
			}
			super.onDestroy();
		}
		
		/** Обработчик нажатия кнопки */
		protected function doButtonClick():void {
			eventSend(new CGEvent(CGEvent.CLICK));
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Ленивое создание таймера автоповторов */
		private function createTimer():void {
			if (mTimer)
				return;
			mTimer = new Timer(1);
			mTimer.addEventListener(TimerEvent.TIMER, onTimer);
		}
		
		/** Обработчик таймера автоповторов */
		private function onTimer(e:TimerEvent):void {
			if (mRepeat) {
				// автоповтор нажатий
				doButtonClick();
			} else {
				// срабатывание после ожидания
				mRepeat = true;
				if (mTimeRate)
					mTimer.delay = mTimeRate;
				mTimer.stop();
				mTimer.start();
				doButtonClick();
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Активность кнопки */
		protected var mEnable:Boolean;
		
		/** Флаг нажатия мыши над кнопкой */
		protected var mPress:Boolean;
		
		/** Флаг включения автоповтора нажатий */
		protected var mRepeat:Boolean;
		
		/** Таймер ожидания и повтора нажатий */
		protected var mTimer:Timer;
		
		/** Время ожидания до автонажатия */
		protected var mTimeWait:int;
		
		/** Интервал между автонажатиями */
		protected var mTimeRate:int;
		
		private static const DISABLE_STATE:String = "disable";
		private static const OVER_STATE:String    = "over";
		private static const OUT_STATE:String     = "out";
		private static const DOWN_STATE:String    = "down";
		private static const UP_STATE:String      = "up";
		private static const LABEL_ID:String      = ".label";
		private static const ICON_ID:String       = ".icon";
		private static const WAIT_DEFAULT:uint    = 0; // ожидание до первого автоматического нажатия
		private static const RATE_DEFAULT:uint    = 300; // период автоматических нажатий
		
	}
	
}
