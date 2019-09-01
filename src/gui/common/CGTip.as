package ui.common {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	/**
	 * Тултип
	 * 
	 * @version  1.0.5
	 * @author   meps
	 */
	public class CGTip extends CGInteractive {
		
		public function CGTip(src:* = null, name:String = null, txt:String = null) {
			m_show = false;
			if (!name)
				name = TIP_ID;
			super(src, name);
			if (txt)
				text = txt;
			m_timer = new Timer(1); // первоначальный интервал не имеет значения
			m_timer.addEventListener(TimerEvent.TIMER, onTimer);
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
			if (time > 0 && !m_timer.running) {
				m_timer.delay = time;
				m_timer.stop();
				m_timer.start();
			} else {
				doShow();
			}
		}
		
		/** Скрыть тултип */
		public function hide():void {
			var time:int = parseInt(constGet(HIDE_CONST));
			if (time > 0 && !m_timer.running) {
				m_timer.delay = time;
				m_timer.stop();
				m_timer.start();
			} else {
				doHide();
			}
		}
		
		public function get isShow():Boolean {
			return m_show;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			CGTipManager.instance.tipRemove(this);
			m_timer.stop();
			m_timer.removeEventListener(TimerEvent.TIMER, onTimer);
			m_timer = null;
			super.onDestroy();
		}
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			if (m_show)
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
			return m_show ? SHOW_STATE : HIDE_STATE;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Фактическое отображение тултипа */
		private function doShow():void {
			m_timer.stop();
			m_show = true;
			doState();
			CGTipManager.instance.tipAdd(this);
			eventSend(new CGEventSwitch(CGEventSwitch.SHOW, m_show));
		}
		
		/** Фактическое скрытие тултипа */
		private function doHide():void {
			m_timer.stop();
			m_show = false;
			CGTipManager.instance.tipRemove(this);
			doState();
			eventSend(new CGEventSwitch(CGEventSwitch.SHOW, m_show));
		}
		
		/** Обработчик автоматического включения отображения и скрытия */
		private function onTimer(e:TimerEvent):void {
			m_timer.stop();
			if (m_show) {
				// завершено время отображения
				doHide();
			} else {
				// завершено время ожидания до отображения
				doShow();
				var time:int = parseInt(constGet(HIDE_CONST));
				if (time > 0) {
					m_timer.delay = time;
					m_timer.start();
				}
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_show:Boolean; // флаг отображения тултипа
		private var m_timer:Timer; // таймер ожидания переключения состояний тултипа
		//private var m_delayShow:int; // время перед автоматическим отображением
		//private var m_delayHide:int; // время перед автоматическим удалением
		
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
