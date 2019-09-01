package flicker.gui {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	/**
	 * Элемент выбора в виде проворачивающегося колеса
	 * 
	 * @version  1.0.7
	 * @author   meps
	 */
	public class CGWheel extends CGProto {
		
		/** Событие смены выбранного значения */
		public static const SELECT:String = "wheel_select";
		
		public function CGWheel(src:* = null, name:String = null) {
			m_position = 0;
			m_target = 0;
			m_list = new Vector.<Object>();
			super(src, name);
			m_buttonPrev = new CGButton(this, PREV_ID);
			m_buttonPrev.eventSign(true, CGEvent.CLICK, onButtonPrev);
			m_buttonNext = new CGButton(this, NEXT_ID);
			m_buttonNext.eventSign(true, CGEvent.CLICK, onButtonNext);
			redrawWheel();
		}
		
		/** Текущий выбранный элемент */
		public function get value():Object {
			if (m_target < 0 || m_target >= m_list.length)
				return null;
			return m_list[m_target];
		}
		
		public function set value(val:Object):void {
			var index:int = m_list.indexOf(val);
			if (index < 0)
				return;
			m_position = index;
			m_target = m_position;
			redrawWheel();
		}
		
		/** Заполнить колесо произвольными данными */
		public function add(val:*):void {
			var i:int, len:int;
			if (val is Array) {
				var arr:Array = val as Array;
				for (i = 0, len = arr.length; i < len; ++i)
					m_list.push(arr[i]);
			} else if (val is Vector.<*>) {
				var vec:Vector.<*> = val as Vector.<*>;
				for (i = 0, len = vec.length; i < len; ++i)
					m_list.push(vec[i]);
			} else {
				m_list.push(val);
			}
			redrawWheel();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			var diff:int = m_target - m_position;
			if (diff == 1)
				return FORWARD_SLOW_STATE;
			else if (diff == -1)
				return BACKWARD_SLOW_STATE;
			else if (diff > 1)
				return FORWARD_FAST_STATE;
			return BACKWARD_FAST_STATE;
		}
		
		override protected function onStateFinish():void {
			if (m_position < m_target) {
				doState();
				redrawWheel();
				++m_position;
			} else if (m_position > m_target) {
				doState();
				--m_position;
				redrawWheel();
			} else {
				redrawWheel();
				if (m_running)
					eventSend(new CGEvent(SELECT));
				m_running = false;
			}
		}
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			mc.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
		
		override protected function onClipRemove(mc:MovieClip):void {
			mc.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			super.onClipRemove(mc);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обновить отображаемые значения */
		private function redrawWheel():void {
			var len:int = m_list.length;
			for (var pos:int = 0, index:int = m_position; pos < 2; ++pos, ++index) {
				var name:String = VALUES_ID + pos.toString();
				var text:String = index < len ? String(m_list[index]) : "";
				textSet(text, name);
			}
		}
		
		private function havePrev():Boolean {
			return m_target > 0;
		}
		
		private function goPrev():void {
			if (!havePrev())
				return;
			--m_target;
			if (m_running)
				return;
			m_running = true;
			onStateFinish();
		}
		
		private function haveNext():Boolean {
			return m_target < (m_list.length - 1);
		}
		
		private function goNext():void {
			if (!haveNext())
				return;
			++m_target;
			if (m_running)
				return;
			m_running = true;
			onStateFinish();
		}
		
		/** Обработчик прокрутки на предыдущую позицию */
		private function onButtonPrev(event:CGEvent):void {
			goPrev();
		}
		
		/** Обработчик прокрутки на следующую позицию */
		private function onButtonNext(event:CGEvent):void {
			goNext();
		}
		
		/** Обработчик вращения колеса мыши */
		private function onMouseWheel(event:MouseEvent):void {
			if (event.delta < 0)
				goNext();
			else if (event.delta > 0)
				goPrev();			
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Текущая позиция */
		private var m_position:int;
		
		/** Целевая позиция */
		private var m_target:int;
		
		/** Список значений допустимых ставок */
		private var m_list:Vector.<Object>;
		
		/** Флаг анимации прокрутки */
		private var m_running:Boolean;
		
		private var m_buttonPrev:CGButton;
		private var m_buttonNext:CGButton;
		
		private static const PREV_ID:String = ".but_prev";
		private static const NEXT_ID:String = ".but_next";
		private static const VALUES_ID:String = ".value_";
		
		private static const FORWARD_FAST_STATE:String = "fastforward";
		private static const BACKWARD_FAST_STATE:String = "fastbackward";
		private static const FORWARD_SLOW_STATE:String = "slowforward";
		private static const BACKWARD_SLOW_STATE:String = "slowbackward";
		
	}

}
