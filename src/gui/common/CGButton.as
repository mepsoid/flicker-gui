package ui.common {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import services.printClass;

	/**
	 * Кнопка для графического интерфейса
	 * 
	 * @version  1.2.18
	 * @author   meps
	 */
	public class CGButton extends CGInteractive {
		
		public function CGButton(src:* = null, name:String = null, lab:String = null) {
			m_enable = true;
			m_press = false;
			m_timeWait = WAIT_DEFAULT;
			m_timeRate = RATE_DEFAULT;
			super(src, name);
			if (lab)
				label = lab;
		}
		
		/** Доступность кнопки для взаимодействия с ней */
		public function get enable():Boolean { return m_enable; }
		
		public function set enable(val:Boolean):void {
			if (m_enable == val)
				return;
			m_enable = val;
			doState();
			// обновить статус области ввода
			var hitMc:MovieClip = objectFind(HIT_ID) as MovieClip;
			if (!hitMc)
				hitMc = clip;
			if (hitMc)
				hitMc.buttonMode = m_enable;
			if (!m_enable) {
				// неактивная кнопка не генерирует автонажатий
				m_repeat = false;
				if (m_timer)
					m_timer.stop();
			}
		}
		
		/** Стандартный ярлык кнопки */
		public function get label():String { return textGet(LABEL_ID); }
		
		public function set label(val:String):void { textSet(val, LABEL_ID); }
		
		/** Стандартная иконка кнопки */
		public function get icon():String { return iconGet(ICON_ID); }
		
		public function set icon(val:String):void { iconSet(val, ICON_ID); }
		
		/** Время ожидания до автонажатий (мс) */
		public function get delayWait():int { return m_timeWait; }
		
		public function set delayWait(val:int):void {
			if (val < 0)
				return;
			m_timeWait = val;
			if (val > 0)
				createTimer();
		}
		
		/** Интервал между автонажатиями (мс) */
		public function get delayRate():int {
			return m_timeRate;
		}
		
		public function set delayRate(val:int):void {
			if (val <= 0)
				return;
			m_timeRate = val;
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
			hitMc.buttonMode = m_enable;
			mc.tabEnabled = false;
			//hitMc.mouseChildren = false;
		}
		
		override protected function onClipRemove(mc:MovieClip):void {
			var hitMc:MovieClip = objectFind(HIT_ID) as MovieClip;
			if (!hitMc)
				hitMc = mc;
			//hitMc.buttonMode = false;
			//hitMc.mouseChildren = true;
			super.onClipRemove(mc);
		}
		
		override protected function onClipMouse(event:MouseEvent):void {
			super.onClipMouse(event);
			if (event.type == MouseEvent.ROLL_OUT) {
				m_press = false;
				if (m_timer)
					m_timer.stop();
			} else if (event.type == MouseEvent.MOUSE_DOWN) {
				m_press = m_over && m_enable;
				m_repeat = false;
				if (m_press && m_timeWait) {
					m_timer.delay = m_timeWait;
					m_timer.start();
				}
			} else if (event.type == MouseEvent.MOUSE_UP) {
				if (m_press && m_enable) {
					if (m_timer)
						m_timer.stop();
					if (!m_repeat || m_timeWait == 0)
						// если еще не было автонажатий или они не используются, при отпускании провести нажатие
						doButtonClick();
				}
				m_press = false;
			}
		}
		
		override protected function doStateValue():String {
			if (m_enable)
				return (m_over ? OVER_STATE : OUT_STATE) + "_" + (m_down ? DOWN_STATE : UP_STATE);
			return DISABLE_STATE;
		}
		
		override protected function onDestroy():void {
			if (m_timer) {
				m_timer.stop();
				m_timer.removeEventListener(TimerEvent.TIMER, onTimer);
				m_timer = null;
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
			if (m_timer)
				return;
			m_timer = new Timer(1);
			m_timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
		}
		
		/** Обработчик таймера автоповторов */
		private function onTimer(e:TimerEvent):void {
			if (m_repeat) {
				// автоповтор нажатий
				doButtonClick();
			} else {
				// срабатывание после ожидания
				m_repeat = true;
				if (m_timeRate)
					m_timer.delay = m_timeRate;
				m_timer.stop();
				m_timer.start();
				doButtonClick();
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Активность кнопки */
		protected var m_enable:Boolean;
		
		/** Флаг нажатия мыши над кнопкой */
		protected var m_press:Boolean;
		
		/** Флаг включения автоповтора нажатий */
		protected var m_repeat:Boolean;
		
		/** Таймер ожидания и повтора нажатий */
		protected var m_timer:Timer;
		
		/** Время ожидания до автонажатия */
		protected var m_timeWait:int;
		
		/** Интервал между автонажатиями */
		protected var m_timeRate:int;
		
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
