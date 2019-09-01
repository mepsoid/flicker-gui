package flicker.gui {
	
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * Тултип
	 * 
	 * @version  1.0.6
	 * @author   meps
	 */
	public class CGTip extends CGInteractive {
		
		public function CGTip(src:* = null, name:String = null, txt:String = null) {
			mShow = false;
			if (!name)
				name = TIP_ID;
			super(src, name);
			if (txt)
				text = txt;
			mTimer = new Timer(1); // первоначальный интервал не имеет значения
			mTimer.addEventListener(TimerEvent.TIMER, onTimer);
			constDefault(SHOW_CONST, SHOW_DEFAULT.toString());
			constDefault(HIDE_CONST, HIDE_DEFAULT.toString());
		}
		
		/** Стандартный текст тултипа */
		public function get text():String {
			return textGet(TEXT_ID);
		}
		
		public function set text(val:String):void {
			textSet(val, TEXT_ID);
		}		
		
		/** Отобразить тултип */
		public function show():void {
			var time:int = parseInt(constGet(SHOW_CONST));
			if (time > 0 && !mTimer.running) {
				mTimer.delay = time;
				mTimer.stop();
				mTimer.start();
			} else {
				doShow();
			}
		}
		
		/** Скрыть тултип */
		public function hide():void {
			var time:int = parseInt(constGet(HIDE_CONST));
			if (time > 0 && !mTimer.running) {
				mTimer.delay = time;
				mTimer.stop();
				mTimer.start();
			} else {
				doHide();
			}
		}
		
		public function get isShow():Boolean {
			return mShow;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			CGTipManager.instance.tipRemove(this);
			mTimer.stop();
			mTimer.removeEventListener(TimerEvent.TIMER, onTimer);
			mTimer = null;
			super.onDestroy();
		}
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			if (mShow)
				CGTipManager.instance.tipAdd(this);
			else
				// временно просто спрятать клип
				mc.visible = false;
		}
		
		override protected function onClipRemove(mc:MovieClip):void {
			CGTipManager.instance.tipRemove(this);			
			super.onClipRemove(mc);
		}
		
		override protected function doStateValue():String {
			return mShow ? SHOW_STATE : HIDE_STATE;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Фактическое отображение тултипа */
		private function doShow():void {
			mTimer.stop();
			mShow = true;
			doState();
			CGTipManager.instance.tipAdd(this);
			eventSend(new CGEventSwitch(CGEventSwitch.SHOW, mShow));
		}
		
		/** Фактическое скрытие тултипа */
		private function doHide():void {
			mTimer.stop();
			mShow = false;
			CGTipManager.instance.tipRemove(this);
			doState();
			eventSend(new CGEventSwitch(CGEventSwitch.SHOW, mShow));
		}
		
		/** Обработчик автоматического включения отображения и скрытия */
		private function onTimer(e:TimerEvent):void {
			mTimer.stop();
			if (mShow) {
				// завершено время отображения
				doHide();
			} else {
				// завершено время ожидания до отображения
				doShow();
				var time:int = parseInt(constGet(HIDE_CONST));
				if (time > 0) {
					mTimer.delay = time;
					mTimer.start();
				}
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mShow:Boolean; // флаг отображения тултипа
		private var mTimer:Timer; // таймер ожидания переключения состояний тултипа
		
		private static const SHOW_STATE:String = "show";
		private static const HIDE_STATE:String = "hide";
		private static const TIP_ID:String     = ".tip";
		private static const TEXT_ID:String    = ".text";
		private static const SHOW_CONST:String = ".show"; // имя константы автопоявления
		private static const HIDE_CONST:String = ".hide"; // имя константы автоудаления
		private static const SHOW_DEFAULT:int = 500; // время автопоявления по умолчанию
		private static const HIDE_DEFAULT:int = 0; // время автоудаления по умолчанию
		
	}

}
