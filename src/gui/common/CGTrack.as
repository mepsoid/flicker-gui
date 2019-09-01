package ui.common {
	
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Трек бар
	 * 
	 * @version  1.0.5
	 * @author   meps
	 */
	public class CGTrack extends CGProto {
		
		/** Событие изменения положения скроллера */
		public static const POSITION:String = "track_position";
		
		/** Событие окончательной установки положения скроллера */
		public static const COMPLETE:String = "track_complete";
		
		public function CGTrack(src:* = null, name:String = null) {
			m_enable = true;
			super(src, name);
			m_butPrev = new CGButton(this, PREV_ID);
			m_butPrev.eventSign(true, CGEvent.CLICK, onPrev);
			m_butPrev.delayWait = DELAY_WAIT;
			m_butPrev.delayRate = DELAY_RATE;
			m_butPrev.enable = m_enable;
			m_butNext = new CGButton(this, NEXT_ID);
			m_butNext.eventSign(true, CGEvent.CLICK, onNext);
			m_butNext.delayWait = DELAY_WAIT;
			m_butNext.delayRate = DELAY_RATE;
			m_butNext.enable = m_enable;
			m_scrollPosition = new CGResizable(this, POSITION_ID);
			m_scrollButton = new CGButton(this, BUTTON_ID);
			m_scrollButton.enable = m_enable;
			m_scrollButton.eventSign(true, CGEvent.DOWN, onButtonDown);
			redrawScroller();
		}
		
		/** Активность элемента */
		public function get enable():Boolean {
			return m_enable;
		}
		
		public function set enable(val:Boolean):void {
			if (val == m_enable)
				return;
			m_enable = val;
			m_butPrev.enable = m_enable;
			m_butNext.enable = m_enable;
			m_scrollButton.enable = m_enable;
			doState();
		}
		
		/** Положение скроллера */
		public function get position():Number {
			return m_position;
		}
		
		public function set position(val:Number):void {
			positionSet(val);
			eventSend(new CGEvent(COMPLETE));
		}
		
		/** Шаг изменения при нажатии на кнопки */
		public function get step():Number {
			return m_step;
		}
		
		public function set step(val:Number):void {
			if (val < LIMIT_LOW)
				val = 0.0;
			else if (val > LIMIT_HIGH)
				val = 1.0;
			if (val == m_step)
				return;
			m_step = val;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			return m_enable ? ENABLE_STATE : DISABLE_STATE;
		}
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			mc.addEventListener(MouseEvent.MOUSE_WHEEL, onAreaWheel, false, 0, true);
			m_area = objectFind(AREA_ID) as InteractiveObject;
			if (!m_area)
				m_area = clip;
			if (!m_area)
				return;
			// подписаться на события области
			m_area.addEventListener(MouseEvent.MOUSE_DOWN, onAreaDown, false, 0, true);
		}
		
		override protected function onClipRemove(mc:MovieClip):void {
			mc.removeEventListener(MouseEvent.MOUSE_WHEEL, onAreaWheel);
			if (m_area) {
				var stage:Stage = m_area.stage;
				if (stage) {
					stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
					stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				}
				m_area.removeEventListener(MouseEvent.MOUSE_DOWN, onAreaDown);
				m_area = null;
			}
			super.onClipRemove(mc);
		}
		
		override protected function onDestroy():void {
			if (clip)
				clip.removeEventListener(MouseEvent.MOUSE_WHEEL, onAreaWheel);
			if (m_area) {
				var stage:Stage = m_area.stage;
				if (stage) {
					stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
					stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				}
				m_area.removeEventListener(MouseEvent.MOUSE_DOWN, onAreaDown);			
				m_area = null;
			}
			m_butPrev.destroy();
			m_butPrev = null;
			m_butNext.destroy();
			m_butNext = null;
			m_scrollPosition.destroy();
			m_scrollPosition = null;
			m_scrollButton.destroy();
			m_scrollButton = null;
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Установить положение скроллера */
		private function positionSet(val:Number):void {
			if (val < LIMIT_LOW)
				val = 0.0;
			else if (val > LIMIT_HIGH)
				val = 1.0;
			if (val == m_position)
				return;
			m_position = val;
			redrawScroller();
			eventSend(new CGEvent(POSITION));
		}
		
		/** Перерисовать положение скроллера */
		private function redrawScroller():void {
			m_butPrev.enable = m_position > LIMIT_LOW;
			m_butNext.enable = m_position < LIMIT_HIGH;
			m_scrollPosition.size = FRAMES_COUNT * m_position;
		}
		
		/** Обработчик кнопки назад */
		private function onPrev(event:CGEvent):void {
			doPrevStep();
		}
		
		/** Передвинуть на шаг к началу */
		private function doPrevStep():void {
			positionSet(m_position - m_step);
		}
		
		/** Обработчик кнопки вперед */
		private function onNext(event:CGEvent):void {
			doNextStep();
		}
		
		/** Передвинуть на шаг к концу */
		private function doNextStep():void {
			positionSet(m_position + m_step);
		}
		
		/** Обработчик колеса мыши */
		private function onAreaWheel(event:MouseEvent):void {
			if (event.delta > 0)
				doPrevStep();
			else if (event.delta < 0)
				doNextStep();
		}
		
		/** Обработчик нажатия на область */
		private function onAreaDown(event:MouseEvent):void {
			var target:DisplayObject = event.target as DisplayObject;
			var coord:Point = new Point(event.stageX, event.stageY);
			var bounds:Rectangle = m_area.getBounds(m_area.stage);
			var ratio:Number = pointRatio(bounds, coord);
			//trace("area", coord, bounds, ratio);
			/*
			if (ratio < m_position)
				// первое нажатие перед скроллером
				doPrevStep();
			else if (ratio > m_position)
				// первое нажатие за скроллером
				doNextStep();
			*/
			// установить новую позицию
			positionSet(ratio);
		}
		
		/** Обработчик нажатия на бегунок */
		private function onButtonDown(event:CGEvent):void {
			if (!m_enable)
				return;
			var target:DisplayObject = m_scrollButton.clip as DisplayObject;
			var coord:Point = new Point(target.stage.mouseX, target.stage.mouseY);
			var bounds:Rectangle = m_area.getBounds(m_area.stage);
			var ratio:Number = pointRatio(bounds, coord);
			//trace("button", coord, bounds, ratio);
			m_offsetRatio = ratio - m_position;
			// первое нажатие было на скроллере
			target.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			target.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		/** Обработчик отпускания кнопки на бегунке */
		private function onMouseUp(event:MouseEvent):void {
			var target:DisplayObject = m_scrollButton.clip as DisplayObject;
			if (!target)
				return;
			// завершить перетаскивание скроллера
			target.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			eventSend(new CGEvent(COMPLETE));
		}
		
		/** Обработчик перемещения курсора мыши */
		private function onMouseMove(event:MouseEvent):void {
			var target:DisplayObject = event.target as DisplayObject;
			var coord:Point = new Point(event.stageX, event.stageY);
			var bounds:Rectangle = m_area.getBounds(m_area.stage);
			var ratio:Number = pointRatio(bounds, coord);
			//trace("move", coord, bounds, ratio);
			// перетаскивать скроллер
			positionSet(ratio - m_offsetRatio);
		}
		
		/** Вычислить линейное соотношение нажатия относительно активной области */
		private function pointRatio(bounds:Rectangle, coord:Point):Number {
			var height:Number = bounds.height;
			var width:Number = bounds.width;
			var ratio:Number = height > width ? ((coord.y - bounds.y) / height) : ((coord.x - bounds.x) / width);
			if (ratio < LIMIT_LOW)
				ratio = 0.0;
			else if (ratio > LIMIT_HIGH)
				ratio = 1.0;
			return ratio;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_enable:Boolean;
		private var m_position:Number;
		private var m_step:Number = 0.1;
		private var m_area:InteractiveObject; // активная область
		private var m_offsetRatio:Number; // отступ первого клика от текущей позиции
		
		private var m_butPrev:CGButton;
		private var m_butNext:CGButton;
		private var m_scrollPosition:CGResizable;
		private var m_scrollButton:CGButton;
		
		private static const PREV_ID:String = ".prev";
		private static const NEXT_ID:String = ".next";
		private static const POSITION_ID:String = ".position";
		private static const AREA_ID:String = ".position.area";
		private static const BUTTON_ID:String = ".position.slider";
		
		private static const ENABLE_STATE:String = "common";
		private static const DISABLE_STATE:String = "disable";
		private static const DELAY_WAIT:int = 500;
		private static const DELAY_RATE:int = 50;
		private static const FRAMES_COUNT:int = 1000;
		private static const LIMIT_LOW:Number = 1 / FRAMES_COUNT; // приведение точности менее одного кадра от крайних положений
		private static const LIMIT_HIGH:Number = 1.0 - LIMIT_LOW;
		
	}

}