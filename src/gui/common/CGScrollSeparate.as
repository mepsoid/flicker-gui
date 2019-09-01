package framework.gui {
	
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import framework.utils.printClass;
	
	import ru.uns.dragons.commands.net.socket.country.UnsubscribeMapUpdates;
	
	/**
	 * Скролл бар на основе разделенных клипов
	 *
	 * @version  1.1.12
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
			mDiscrete = false
			mEnable = true;
			mSize = 1.0;
			mPosition = 0.0;
			mPositionTarget = 0.0;
			mStep = 0.1;
			mLength = 0.0;
			mOffsetRatio = 0.0;
			super(src, name);
			// кнопка предыдущей позиции
			mButPrev = new CGButton(this, mName + PREV_SUFFIX);
			mButPrev.eventSign(true, CGEvent.CLICK, onButtonPrev);
			mButPrev.delayWait = DELAY_WAIT;
			mButPrev.delayRate = DELAY_RATE;
			mButPrev.enable = mEnable;
			// кнопка следующей позиции
			mButNext = new CGButton(this, mName + NEXT_SUFFIX);
			mButNext.eventSign(true, CGEvent.CLICK, onButtonNext);
			mButNext.delayWait = DELAY_WAIT;
			mButNext.delayRate = DELAY_RATE;
			mButNext.enable = mEnable;
			// кнопка начала списка
			mButFirst = new CGButton(this, mName + FIRST_SUFFIX);
			mButFirst.eventSign(true, CGEvent.CLICK, onButtonFirst);
			mButFirst.enable = mEnable;
			// кнопка конца списка
			mButLast = new CGButton(this, mName + LAST_SUFFIX);
			mButLast.eventSign(true, CGEvent.CLICK, onButtonLast);
			mButLast.enable = mEnable;
			// кнопка бегунок
			mButSlider = new CGButton(this, mName + SLIDER_SUFFIX);
			mButSlider.enable = mEnable;
			mButSlider.eventSign(true, CGEvent.DOWN, onButtonSlider);
			// все перерисовать
			wheelSubscribe();
			redrawButtons();
			redrawScroller();
		}
		
		/** Активность элемента */
		public function get enable():Boolean {
			return mEnable;
		}
		
		public function set enable(val:Boolean):void {
			if (val == mEnable)
				return;
			mEnable = val;
			redrawButtons();
		}
		
		/** Размер отображаемого фрагмента */
		public function get size():Number {
			return mSize;
		}
		
		public function set size(val:Number):void {
			if (val < 0.0)
				val = 0.0;
			if (mDiscrete) {
				if (val > mLength)
					val = mLength;
				val = int(val);
			} else {
				if (val > 1.0)
					val = 1.0;
			}
			if (val == mSize)
				return;
			mSize = val;
			if (mDiscrete) {
				if (mPosition > mLength - mSize) {
					positionSet(mLength - mSize);
					targetSet(mPosition); // привести целевую позицию к текущей
				} else {
					redrawButtons();
					redrawScroller();
				}
			} else {
				if (mPosition > 1.0 - mSize) {
					positionSet(1.0 - mSize);
					targetSet(mPosition); // привести целевую позицию к текущей
				} else {
					redrawButtons();
					redrawScroller();
				}
			}
			eventSend(new CGEvent(SIZE));
		}
		
		/** Положение скроллера */
		public function get position():Number {
			return mPosition;
		}
		
		public function set position(val:Number):void {
			positionSet(val);
			targetSet(mPosition); // привести целевую позицию к текущей
			eventSend(new CGEvent(COMPLETE));
		}
		
		/** Шаг изменения при нажатии на кнопки */
		public function get step():Number {
			return mStep;
		}
		
		public function set step(val:Number):void {
			if (val < 0.0)
				val = 0.0;
			if (mDiscrete) {
				val = int(val);
			} else {
				if (val > 1.0)
					val = 1.0;
			}
			if (val == mStep)
				return;
			mStep = val;
		}
		
		/** Полная длина списка */
		public function get length():Number {
			if (mDiscrete)
				return mLength;
			return 1.0;
		}
		
		public function set length(val:Number):void {
			if (!mDiscrete)
				return;
			if (val == mLength)
				return;
			mLength = val;
			redrawButtons();
			redrawScroller();
		}
		
		/** Дискретный скроллер, все положения и размеры целые числа */
		public function get discrete():Boolean {
			return mDiscrete;
		}
		
		public function set discrete(val:Boolean):void {
			if (val == mDiscrete)
				return;
			mDiscrete = val;
			redrawButtons();
			redrawScroller();
		}
		
		public function get buttonPrev():CGButton {
			return mButPrev;
		}
		
		public function get buttonNext():CGButton {
			return mButNext;
		}
		
		public function get buttonSlider():CGButton {
			return mButSlider;
		}
		
		override public function toString():String {
			return printClass(this, "enable", "size", "position", "step", "length", "discrete");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			wheelUnsubscribe();
			frameUnsubscribe();
			mButPrev.destroy();
			mButPrev = null;
			mButNext.destroy();
			mButNext = null;
			mButFirst.destroy();
			mButFirst = null;
			mButLast.destroy();
			mButLast = null;
			mButSlider.destroy();
			mButSlider = null;
			if (mClipArea) {
				var stage:Stage = mClipArea.stage;
				if (stage) {
					stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
					stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				}
				mClipArea.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				mClipArea.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				mClipArea = null;
			}
			if (mClipWheel) {
				mClipWheel.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				mClipWheel = null;
			}
			super.onDestroy();
		}
		
		override protected function doClipProcess():void {
			super.doClipProcess();
			// обновить активную область
			var area:InteractiveObject = objectFind(mName + AREA_SUFFIX) as InteractiveObject;
			if (mClipArea !== area) {
				if (mClipArea) {
					mClipArea.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
					mClipArea.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				}
				mClipArea = area;
				if (mClipArea) {
					mClipArea.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
					mClipArea.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
				}
			}
			// обновить область скроллинга
			var wheelClip:InteractiveObject = objectFind(mName + WHEEL_SUFFIX) as InteractiveObject
			
			var wheel:InteractiveObject;
			if(wheelClip)
				wheel = wheelClip.parent;
			if (mClipWheel !== wheel) {
				if (mClipWheel)
					mClipWheel.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				mClipWheel = wheel;
				if (mClipWheel)
					mClipWheel.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			}
			// перерисовать скроллер
			redrawScroller();
		}
		
		override protected function onClipParent():void {
			super.onClipParent();
			wheelUnsubscribe();
			wheelSubscribe();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Установить положение скроллера */
		private function positionSet(val:Number):void {
			if (val <= EPSILON)
				val = 0.0;
			if (mDiscrete) {
				if (val >= (mLength - EPSILON - mSize))
					val = mLength - mSize;
				val = int(val);
			} else {
				if (val >= (1.0 - EPSILON - mSize))
					val = 1.0 - mSize;
			}
			if (val == mPosition)
				return;
			mPosition = val;
			redrawButtons();
			redrawScroller();
			eventSend(new CGEvent(POSITION));
		}
		
		/** Установить целевое положение скроллера */
		private function targetSet(val:Number):void {
			if (val <= EPSILON)
				val = 0.0;
			if (mDiscrete) {
				if (val >= (mLength - EPSILON - mSize))
					val = mLength - mSize;
				val = int(val);
			} else {
				if (val >= (1.0 - EPSILON - mSize))
					val = 1.0 - mSize;
			}
			if (val == mPosition) {
				// не начинать никакого плавного движения, позиция и так совпала с текущей
				frameUnsubscribe();
				mPositionTarget = val;
				return;
			}
			// пересчитать ускорение и время
			mTimeLast = getTimer();
			if (mTimeLast > mTimeTarget)
				// если предыдущее движение уже было завершено, снова подписаться на обновление кадров
				frameSubscribe();
			mTimeTarget = mTimeLast + WHEEL_TIME;
			mPositionTarget = val;
			mPositionAccel = 2.0 * (mPosition - mPositionTarget) / (WHEEL_TIME * WHEEL_TIME);
			mPositionSpeed = -mPositionAccel * WHEEL_TIME;
		}
		
		/** Перерисовать состояние кнопок */
		private function redrawButtons():void {
			var ready:Boolean, forward:Boolean, back:Boolean;
			if (mDiscrete) {
				ready = mEnable && (mSize < mLength);
				back = ready && (mPosition > 0.0);
				forward = ready && (mPosition < mLength - mSize);
			} else {
				ready = mEnable && (mSize < 1.0);
				back = ready && (mPosition > 0.0);
				forward = ready && (mPosition < 1.0 - mSize);
			}
			mButPrev.enable = back;
			mButNext.enable = forward;
			mButFirst.enable = back;
			mButLast.enable = forward;
			mButSlider.enable = ready;
			iconSet(mEnable ? COMMON_STATE : DISABLE_STATE, mName + BACK_SUFFIX);
		}
		
		/** Перерисовать положение бегунка */
		private function redrawScroller():void {
			if (!mClipArea)
				return;
			var areaBounds:Rectangle = mClipArea.getRect(mClipArea.parent);
			// спозиционировать бегунок по области
			if (mButSlider) {
				var slider:MovieClip = mButSlider.clip;
				if (slider) {
					if (areaBounds.width > areaBounds.height) {
						// горизонтальный трекбар
						slider.y = areaBounds.top;
						slider.height = areaBounds.height;
						if (mDiscrete) {
							slider.x = mPosition / mLength * areaBounds.width + areaBounds.left;
							slider.width = mSize / mLength * areaBounds.width;
						} else {
							slider.x = mPosition * areaBounds.width + areaBounds.left;
							slider.width = mSize * areaBounds.width;
						}
					} else {
						// вертикальный трекбар
						slider.x = areaBounds.left;
						slider.width = areaBounds.width;
						if (mDiscrete) {
							slider.y = mPosition / mLength * areaBounds.height + areaBounds.top;
							slider.height = mSize / mLength * areaBounds.height;
						} else {
							slider.y = mPosition * areaBounds.height + areaBounds.top;
							slider.height = mSize * areaBounds.height;
						}
					}
				}
			}
		}
		
		/** Передвинуть на шаг к началу */
		private function doPrevStep():void {
			positionSet(mPosition - mStep);
			targetSet(mPosition); // привести целевую позицию к текущей
		}
		
		/** Передвинуть на шаг к концу */
		private function doNextStep():void {
			positionSet(mPosition + mStep);
			targetSet(mPosition); // привести целевую позицию к текущей
		}
		
		/** Обработчик кнопки назад */
		private function onButtonPrev(event:CGEvent):void {
			doPrevStep();
		}
		
		/** Обработчик кнопки вперед */
		private function onButtonNext(event:CGEvent):void {
			doNextStep();
		}
		
		/** Обработчик кнопки начала списка */
		private function onButtonFirst(event:CGEvent):void {
			positionSet(0.0);
			targetSet(mPosition); // привести целевую позицию к текущей
		}
		
		/** Обработчик кнопки конца списка */
		private function onButtonLast(event:CGEvent):void {
			positionSet(1.0);
			targetSet(mPosition); // привести целевую позицию к текущей
		}
		
		/** Обработчик нажатия на бегунок */
		private function onButtonSlider(event:CGEvent):void {
			if (!mClipArea)
				return;
			var stage:Stage = mClipArea.stage;
			var coord:Point = new Point(stage.mouseX, stage.mouseY);
			var bounds:Rectangle = mClipArea.getRect(stage);
			var ratio:Number = pointRatio(bounds, coord);
			mOffsetRatio = ratio - mPosition - mSize * 0.5;
			// первое нажатие было на скроллере
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
			mButSlider.eventSign(true, CGEvent.UP, onSliderMouseUp);
		}
		
		/** Обработчик колеса мыши */
		private function onMouseWheel(event:MouseEvent):void {
			if (!mEnable)
				return;
			if (event.delta > 0) {
				if (mDiscrete)
					doPrevStep();
				else
					targetSet(mPositionTarget - mStep);
			} else if (event.delta < 0) {
				if (mDiscrete)
					doNextStep();
				else
					targetSet(mPositionTarget + mStep);
			}
		}
		
		/** Обработчик отпускания кнопки на бегунке */
		private function onSliderMouseUp(event:CGEvent):void {
			if (!mClipArea)
				return;
			var stage:Stage = mClipArea.stage;
			mButSlider.eventSign(false, CGEvent.UP, onSliderMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			eventSend(new CGEvent(COMPLETE));
			mOffsetRatio = 0.0;
		}
		
		/** Обработчик отпускания кнопки на stage */
		private function onMouseUp(event:MouseEvent):void {
			var stage:Stage = (event.target as DisplayObject).stage;
			// завершить перетаскивание скроллера
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			mButSlider.eventSign(false, CGEvent.UP, onSliderMouseUp);
			eventSend(new CGEvent(COMPLETE));
			mOffsetRatio = 0.0;
		}
		
		/** Обработчик нажатия на область */
		private function onMouseDown(event:MouseEvent):void {
			onMouseMove(event);
			eventSend(new CGEvent(COMPLETE));
		}
		
		/** Обработчик перемещения курсора мыши */
		private function onMouseMove(event:MouseEvent):void {
			if (!mClipArea || !mEnable)
				return;
			var coord:Point = new Point(event.stageX, event.stageY);
			var bounds:Rectangle = mClipArea.getRect(mClipArea.stage);
			var ratio:Number = pointRatio(bounds, coord);
			// перетаскивать скроллер
			positionSet(ratio - mOffsetRatio - mSize * 0.5);
			targetSet(mPosition); // привести целевую позицию к текущей
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
		private function wheelSubscribe():void {
			var but:MovieClip;
			if (mButPrev) {
				but = mButPrev.clip;
				if (but)
					but.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			}
			if (mButNext) {
				but = mButNext.clip;
				if (but)
					but.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			}
			if (mButSlider) {
				but = mButSlider.clip;
				if (but)
					but.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
			}
			
			if (mClipArea) {
				var stage:Stage = mClipArea.stage;
				if (stage) {
					stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				}
			}
		}
		
		/** Удалить с кнопок подписки на колесо */
		private function wheelUnsubscribe():void {
			var but:MovieClip;
			if (mButPrev) {
				but = mButPrev.clip;
				if (but)
					but.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			if (mButNext) {
				but = mButNext.clip;
				if (but)
					but.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			if (mButSlider) {
				but = mButSlider.clip;
				if (but)
					but.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			if (mClipArea) {
				var stage:Stage = mClipArea.stage;
				if (stage) {
					stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				}
			}
		}
		
		public function unsibscribeStageListeners():void
		{
			wheelUnsubscribe();
		}
		
		/** Обработчик входа в кадр для расчета текущей позиции */
		private function onPositionFrame(event:Event):void {
			var time:int = getTimer();
			if (time > mTimeTarget) {
				// дошли до финального времени, отписаться от кадров
				var target:DisplayObject = event.target as DisplayObject;
				target.removeEventListener(Event.ENTER_FRAME, onPositionFrame);
				mPositionSpeed = 0.0;
				mPositionAccel = 0.0;
				positionSet(mPositionTarget);
				return;
			}
			// время еще есть, пересчитать промежуточное положение и скорость
			var timeDelta:Number = time - mTimeLast;
			mTimeLast = time;
			var pos:Number = mPosition + mPositionSpeed * timeDelta + mPositionAccel * timeDelta * timeDelta / 2.0;
			mPositionSpeed += mPositionAccel * timeDelta;
			positionSet(pos);
		}
		
		/** Подписаться на кадры для отработки плавной прокрутки */
		private function frameSubscribe():void {
			if (mClipWheel) {
				mClipWheel.addEventListener(Event.ENTER_FRAME, onPositionFrame, false, 0, true);
				return;
			}
			//CONFIG::debug { trace("CGScrollSeparate::frameSubscribe", "no m_clipWheel!"); }
			var but:MovieClip;
			if (mButPrev) {
				but = mButPrev.clip;
				if (but) {
					but.addEventListener(Event.ENTER_FRAME, onPositionFrame, false, 0, true);
					return;
				}
			}
			if (mButNext) {
				but = mButNext.clip;
				if (but) {
					but.addEventListener(Event.ENTER_FRAME, onPositionFrame, false, 0, true);
					return;
				}
			}
			if (mButSlider) {
				but = mButSlider.clip;
				if (but) {
					but.addEventListener(Event.ENTER_FRAME, onPositionFrame, false, 0, true);
					return;
				}
			}
			// здесь делать уже нечего, т.к. событие колеса, требующее плавной прокрутки все равно получить больше неоткуда
		}
		
		/** Отписаться от кадров отработки плавной прокрутки */
		private function frameUnsubscribe():void {
			if (mClipWheel)
				mClipWheel.removeEventListener(Event.ENTER_FRAME, onPositionFrame);
			//CONFIG::debug { if (!m_clipWheel) trace("CGScrollSeparate::frameUnsubscribe", "no m_clipWheel!"); }
			var but:MovieClip;
			if (mButPrev) {
				but = mButPrev.clip;
				if (but)
					but.removeEventListener(Event.ENTER_FRAME, onPositionFrame);
			}
			if (mButNext) {
				but = mButNext.clip;
				if (but)
					but.removeEventListener(Event.ENTER_FRAME, onPositionFrame);
			}
			if (mButSlider) {
				but = mButSlider.clip;
				if (but)
					but.removeEventListener(Event.ENTER_FRAME, onPositionFrame);
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mDiscrete:Boolean; // флаг скроллера с дискретными значениями
		private var mEnable:Boolean;
		private var mSize:Number;
		private var mPosition:Number;
		private var mPositionTarget:Number; // целевая позиция при прокрутке колесом
		private var mStep:Number;
		private var mLength:Number; // полная длина списка
		private var mOffsetRatio:Number; // отступ первого клика от текущей позиции
		
		private var mTimeLast:int; // последнее время измерения
		private var mTimeTarget:int; // финальное время за которое стремится завершиться движение
		private var mPositionSpeed:Number; // текущая скорость изменения позиции; пересчитывается на каждой итерации
		private var mPositionAccel:Number; // текущее ускорение; пересчитывается только при смене позиции
		
		private var mButPrev:CGButton;
		private var mButNext:CGButton;
		private var mButFirst:CGButton;
		private var mButLast:CGButton;
		private var mButSlider:CGButton;
		private var mClipArea:InteractiveObject;
		private var mClipWheel:InteractiveObject;
		
		private static const PREV_SUFFIX:String = "_prev";
		private static const NEXT_SUFFIX:String = "_next";
		private static const FIRST_SUFFIX:String = "_first";
		private static const LAST_SUFFIX:String = "_last";
		private static const SLIDER_SUFFIX:String = "_slider";
		private static const AREA_SUFFIX:String = "_area";
		private static const WHEEL_SUFFIX:String = "_wheel";
		private static const BACK_SUFFIX:String = "_back";
		
		private static const COMMON_STATE:String = "common";
		private static const DISABLE_STATE:String = "disable";
		
		private static const DELAY_WAIT:int = 500;
		private static const DELAY_RATE:int = 50;
		private static const EPSILON:Number = 0.0001;
		private static const WHEEL_TIME:int = 450; // время (мс) за которое должен быть пройден оставшийся путь при вращении колеса
		
	}

}
