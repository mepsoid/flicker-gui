package ui.common {
	
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	/**
	 * Скролл бар на основе разделенных клипов
	 * 
	 * @version  1.0.5
	 * @author   meps
	 */
	public class CGScrollSeparate extends CGSeparate {
		
		/** Событие изменения размеров скроллера */
		public static const SIZE:String = "scroll_size";
		
		/** Событие изменения положения скроллера */
		public static const POSITION:String = "scroll_position";
		
		/** Событие окончательной установки положения скроллера */
		public static const COMPLETE:String = "scroll_complete";
		
		public function CGScrollSeparate(src:* = null, name:String = null) {
			m_enable = true;
			m_size = 1.0;
			m_position = 0.0;
			m_positionTarget = 0.0;
			m_step = 0.1;
			m_offsetRatio = 0.0;
			m_wheelTimer = new Timer(WHEEL_RATE);
			m_wheelTimer.addEventListener(TimerEvent.TIMER, onWheelTimer, false, 0, true);
			super(src, name);
			// кнопка предыдущей позиции
			m_butPrev = new CGButton(this, m_name + PREV_SUFFIX);
			m_butPrev.eventSign(true, CGEvent.CLICK, onButtonPrev);
			m_butPrev.delayWait = DELAY_WAIT;
			m_butPrev.delayRate = DELAY_RATE;
			m_butPrev.enable = m_enable;
			// кнопка следующей позиции
			m_butNext = new CGButton(this, m_name + NEXT_SUFFIX);
			m_butNext.eventSign(true, CGEvent.CLICK, onButtonNext);
			m_butNext.delayWait = DELAY_WAIT;
			m_butNext.delayRate = DELAY_RATE;
			m_butNext.enable = m_enable;
			// кнопка бегунок
			m_butSlider = new CGButton(this, m_name + SLIDER_SUFFIX);
			m_butSlider.enable = m_enable;
			m_butSlider.eventSign(true, CGEvent.DOWN, onButtonSlider);
			// все перерисовать
			subscribeWheel();
			redrawButtons();
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
			redrawButtons();
		}
		
		/** Размер отображаемого фрагмента */
		public function get size():Number {
			return m_size;
		}
		
		public function set size(val:Number):void {
			if (val < 0.0)
				val = 0.0;
			else if (val > 1.0)
				val = 1.0;
			if (val == m_size)
				return;
			m_size = val;
			if (m_position > 1.0 - m_size) {
				positionSet(1.0 - m_size);
				targetSet(m_position); // привести целевую позицию к текущей
			} else {
				redrawButtons();
				redrawScroller();
			}
			eventSend(new CGEvent(SIZE));
		}
		
		/** Положение скроллера */
		public function get position():Number {
			return m_position;
		}
		
		public function set position(val:Number):void {
			positionSet(val);
			targetSet(m_position); // привести целевую позицию к текущей
			eventSend(new CGEvent(COMPLETE));
		}
		
		/** Шаг изменения при нажатии на кнопки */
		public function get step():Number {
			return m_step;
		}
		
		public function set step(val:Number):void {
			if (val < 0.0)
				val = 0.0;
			else if (val > 1.0)
				val = 1.0;
			if (val == m_step)
				return;
			m_step = val;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			unsubscribeWheel();
			m_wheelTimer.stop()
			m_wheelTimer.removeEventListener(TimerEvent.TIMER, onWheelTimer);
			m_wheelTimer = null;
			m_butPrev.destroy();
			m_butPrev = null;
			m_butNext.destroy();
			m_butNext = null;
			m_butSlider.destroy();
			m_butSlider = null;
			if (m_clipArea) {
				var stage:Stage = m_clipArea.stage;
				if (stage) {
					stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
					stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				}
				m_clipArea.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseMove);
				m_clipArea.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				m_clipArea = null;
			}
			if (m_clipWheel) {
				m_clipWheel.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				m_clipWheel = null;
			}
			super.onDestroy();
		}
		
		override protected function doClipProcess():void {
			super.doClipProcess();
			// обновить активную область
			var area:InteractiveObject = objectFind(m_name + AREA_SUFFIX) as InteractiveObject;
			if (m_clipArea !== area) {
				if (m_clipArea) {
					m_clipArea.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseMove);
					m_clipArea.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				}
				m_clipArea = area;
				if (m_clipArea) {
					m_clipArea.addEventListener(MouseEvent.MOUSE_DOWN, onMouseMove, false, 0, true);
					m_clipArea.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
				}
			}
			// обновить область скроллинга
			var wheel:InteractiveObject = objectFind(m_name + WHEEL_SUFFIX) as InteractiveObject;
			if (m_clipWheel !== wheel) {
				if (m_clipWheel)
					m_clipWheel.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				m_clipWheel = wheel;
				if (m_clipWheel)
					m_clipWheel.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			}
			// перерисовать скроллер
			redrawScroller();
		}
		
		override protected function onClipParent():void {
			super.onClipParent();
			unsubscribeWheel();
			subscribeWheel();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Установить положение скроллера */
		private function positionSet(val:Number):void {
			if (val <= EPSILON)
				val = 0.0;
			else if (val >= (1.0 - EPSILON - m_size))
				val = 1.0 - m_size;
			if (val == m_position)
				return;
			m_position = val;
			redrawButtons();
			redrawScroller();
			eventSend(new CGEvent(POSITION));
		}
		
		/** Установить целевое положение скроллера */
		private function targetSet(val:Number):void {
			if (val <= EPSILON)
				val = 0.0;
			else if (val >= (1.0 - EPSILON - m_size))
				val = 1.0 - m_size;
			if (val == m_position) {
				m_wheelTimer.stop();
				m_positionTarget = val;
				return;
			}
			m_positionTarget = val;
			m_wheelTimer.start();
		}
		
		/** Перерисовать состояние кнопок */
		private function redrawButtons():void {
			var ready:Boolean = m_enable && m_size < 1.0;
			m_butPrev.enable = ready && m_position > 0.0;
			m_butNext.enable = ready && m_position < 1.0 - m_size;
			m_butSlider.enable = ready;
			iconSet(m_enable ? COMMON_STATE : DISABLE_STATE, m_name + BACK_SUFFIX);
		}
		
		/** Перерисовать положение бегунка */
		private function redrawScroller():void {
			if (!m_clipArea)
				return;
			var areaBounds:Rectangle = m_clipArea.getRect(m_clipArea.parent);
			// спозиционировать бегунок по области
			if (m_butSlider) {
				var slider:MovieClip = m_butSlider.clip;
				if (slider) {
					if (areaBounds.width > areaBounds.height) {
						// горизонтальный трекбар
						slider.x = m_position * areaBounds.width + areaBounds.left;
						slider.y = areaBounds.top;
						slider.width = m_size * areaBounds.width;
						slider.height = areaBounds.height;
					} else {
						// вертикальный трекбар
						slider.x = areaBounds.left;
						slider.y = m_position * areaBounds.height + areaBounds.top;
						slider.width = areaBounds.width;
						slider.height = m_size * areaBounds.height;
					}
				}
			}
		}
		
		/** Передвинуть на шаг к началу */
		private function doPrevStep():void {
			positionSet(m_position - m_step);
			targetSet(m_position); // привести целевую позицию к текущей
		}
		
		/** Передвинуть на шаг к концу */
		private function doNextStep():void {
			positionSet(m_position + m_step);
			targetSet(m_position); // привести целевую позицию к текущей
		}
		
		/** Обработчик кнопки назад */
		private function onButtonPrev(event:CGEvent):void {
			doPrevStep();
		}
		
		/** Обработчик кнопки вперед */
		private function onButtonNext(event:CGEvent):void {
			doNextStep();
		}
		
		/** Обработчик нажатия на бегунок */
		private function onButtonSlider(event:CGEvent):void {
			if (!m_clipArea)
				return;
			var stage:Stage = m_clipArea.stage;
			var coord:Point = new Point(stage.mouseX, stage.mouseY);
			var bounds:Rectangle = m_clipArea.getRect(stage);
			var ratio:Number = pointRatio(bounds, coord);
			m_offsetRatio = ratio - m_position - m_size * 0.5;
			// первое нажатие было на скроллере
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
		}
		
		/** Обработчик колеса мыши */
		private function onMouseWheel(event:MouseEvent):void {
			if (!m_enable)
				return;
			if (event.delta > 0)
				targetSet(m_positionTarget - m_step);
				//doPrevStep();
			else if (event.delta < 0)
				targetSet(m_positionTarget + m_step);
				//doNextStep();
		}
		
		/** Обработчик отпускания кнопки на бегунке */
		private function onMouseUp(event:MouseEvent):void {
			var stage:Stage = (event.target as DisplayObject).stage;
			// завершить перетаскивание скроллера
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			eventSend(new CGEvent(COMPLETE));
			m_offsetRatio = 0.0;
		}
		
		/** Обработчик нажатия на область и перемещения курсора мыши */
		private function onMouseMove(event:MouseEvent):void {
			if (!m_clipArea || !m_enable)
				return;
			var coord:Point = new Point(event.stageX, event.stageY);
			var bounds:Rectangle = m_clipArea.getRect(m_clipArea.stage);
			var ratio:Number = pointRatio(bounds, coord);
			// перетаскивать скроллер
			positionSet(ratio - m_offsetRatio - m_size * 0.5);
			targetSet(m_position); // привести целевую позицию к текущей
		}
		
		/** Обработчик таймера при прокрутке колесом */
		private function onWheelTimer(event:TimerEvent):void {
			// прокручивать до целевой позиции
			var subStep:Number = (m_positionTarget - m_position) * WHEEL_EASING;
			if (subStep > -EPSILON && subStep < EPSILON) {
				// текущая позиция достигла целевой
				m_wheelTimer.stop();
				positionSet(m_positionTarget);
			} else {
				// прокрутить на шаг
				positionSet(m_position + subStep);
			}
		}
		
		/** Вычислить линейное соотношение нажатия относительно активной области */
		private function pointRatio(bounds:Rectangle, coord:Point):Number {
			var height:Number = bounds.height;
			var width:Number = bounds.width;
			var ratio:Number;
			if (height > width)
				ratio = (coord.y - bounds.y) / height;
			else
				ratio = (coord.x - bounds.x) / width;
			return ratio;
		}
		
		/** Дополнить кнопки подписками на колесо */
		private function subscribeWheel():void {
			var but:MovieClip;
			if (m_butPrev) {
				but = m_butPrev.clip;
				if (but)
					but.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			}
			if (m_butNext) {
				but = m_butNext.clip;
				if (but)
					but.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			}
			if (m_butSlider) {
				but = m_butSlider.clip;
				if (but)
					but.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			}
		}
		
		/** Удалить с кнопок подписки на колесо */
		private function unsubscribeWheel():void {
			var but:MovieClip;
			but = m_butPrev.clip;
			if (but)
				but.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			but = m_butNext.clip;
			if (but)
				but.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			but = m_butSlider.clip;
			if (but)
				but.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_enable:Boolean;
		private var m_size:Number;
		private var m_position:Number;
		private var m_positionTarget:Number; // целевая позиция при прокрутке колесом
		private var m_step:Number;
		private var m_offsetRatio:Number; // отступ первого клика от текущей позиции
		private var m_wheelTimer:Timer; // таймер для отработки прокрутки колесом
		
		private var m_butPrev:CGButton;
		private var m_butNext:CGButton;
		private var m_butSlider:CGButton;
		private var m_clipArea:InteractiveObject;
		private var m_clipWheel:InteractiveObject;
		
		private static const PREV_SUFFIX:String = "_prev";
		private static const NEXT_SUFFIX:String = "_next";
		private static const SLIDER_SUFFIX:String = "_slider";
		private static const AREA_SUFFIX:String = "_area";
		private static const WHEEL_SUFFIX:String = "_wheel";
		private static const BACK_SUFFIX:String = "_back";
		
		private static const COMMON_STATE:String = "common";
		private static const DISABLE_STATE:String = "disable";
		
		private static const DELAY_WAIT:int = 500;
		private static const DELAY_RATE:int = 50;
		private static const EPSILON:Number = 0.0001;
		private static const WHEEL_EASING:Number = 0.35; // коэффициент замедления при прокрутке колесом
		private static const WHEEL_RATE:int = 50; // интервал времени при отрисовке субшагов прокрутки
		
	}

}