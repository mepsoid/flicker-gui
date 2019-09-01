package flicker.gui {
	
	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	/**
	 * Прототип элементов графического интерфейса
	 *
	 * @version  1.4.37
	 * @author   meps
	 */
	public class CGProto extends CGContainer {
		
		public function CGProto(src:* = null, name:String = null) {
			mFrame = 0;
			mClipFrame = 0;
			mFramesName = new Vector.<String>();
			mFramesStart = new Vector.<int>();
			mFramesFinish = new Vector.<int>();
			super(src, name);
		}
		
		public function stateHave(name:String):Boolean
		{
			return mFramesName.indexOf(name) != -1;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Текущее значение состояния */
		protected function doStateValue():String {
			return "default";
		}
		
		/** Привести клип в соответствие с текущим состоянием */
		protected function doState():void {
			var state:String = doStateValue();
			doClipState(state, false);
		}
		
		/** Обработчик смены состояния связанного родительского элемента */
		override protected function onClipParent():void {
			// найти по имени клип в родительском элементе
			var mc:MovieClip = mParent.objectFind(mClipName) as MovieClip;
			if (mc) {
				// найден соответствующий клип
				if (mc === clip) {
					// сам клип сохранился, просто обновить его
					doClipProcess();
				} else {
					// полностью заменить клип
					doClipRemove();
					doClipAppend(mc);
					//doClipState(m_state, true);
					//doClipProcess();
				}
			} else {
				// клипа в новом состоянии нет, удалить старый
				doClipRemove();
				eventSend(new CGEvent(UPDATE));
			}
		}
		
		/** Зарегистрировать клип, подготовить данные по кадрам анимаций */
		override protected function onClipAppend(mc:MovieClip):void {
			mClipFrame = 0;
			mFramesName.length = 0;
			mFramesStart.length = 0;
			mFramesFinish.length = 0;
			var state:String = doStateValue();
			if (mc) {
				mc.stop();
				// собрать кадры анимации по именам
				var labelList:Array/*FrameLabel*/ = (mc.scenes[0] as Scene).labels as Array/*FrameLabel*/;
				var frameFinish:int = mc.totalFrames + 1; // последний используемый кадр
				var frameFirst:int = frameFinish; // первый используемый кадр
				for (var index:int = labelList.length - 1; index >= 0; --index) {
					var label:FrameLabel = labelList[index] as FrameLabel;
					var s:String = label.name;
					var j:int = mFramesName.indexOf(s);
					if (j < 0) {
						j = mFramesName.length;
						mFramesName[j] = s;
					}
					var frameLabel:int = label.frame;
					if (frameLabel < frameFirst) {
						// перемещать первый кадр только если он менялся
						if (frameFirst < frameFinish)
							frameFinish = frameFirst;
						frameFirst = frameLabel;
					}
					mFramesStart[j] = frameFirst;
					mFramesFinish[j] = frameFinish;
				}
			}
			doClipState(state, true);
		}
		
		/** Удалить регистрацию клипа */
		override protected function onClipRemove(mc:MovieClip):void {
			mClipFrame = 0;
			if (clip) {
				clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				clip.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			}
		}
		
		override protected function onDestroy():void {
			if (clip) {
				clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				clip.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			}
			mFramesName = null;
			mFramesStart = null;
			mFramesFinish = null;
			super.onDestroy();
		}
		
		/** Сменить состояние со старого на новое */
		protected function doClipState(stat:String, cont:Boolean = false):void {
			// TODO cont -- задел на будущее, чтобы можно было плавно продолжать ведущиеся анимации переходов при смене клипов в парентах
			var frame:int;
			if (!clip || !stat)
				return;
			clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			// проверить на наличие предыдущей анимации
			var transIndex:int = mFramesName.indexOf(mState + ":" + stat);
			var stateIndex:int = mFramesName.indexOf(stat); // соответствующий новому состоянию индекс
			mState = stat;
			mFrameTime = getTimer();
			if (mClipFrame == 0) {
				// первоначальное состояние
				mFrameStart = 0;
				mFrameFinish = 0;
				mFrameResult = stateIndex < 0 ? 1 : mFramesStart[stateIndex];
				mFrame = mFrameResult;
				// несколько костылеобразно: ожидать следующего кадра для начальной инициализации клипа
				//clip.addEventListener(Event.ENTER_FRAME, onEnterFrame);
				//return;
				processFrame();
			} else if (transIndex >= 0) {
				// есть переход между состояниями
				var frameStart:int = mFrameStart;
				var frameFinish:int = mFrameFinish;
				mFrameStart = mFramesStart[transIndex];
				mFrameFinish = mFramesFinish[transIndex];
				if (frameStart != mFrameStart || frameFinish != mFrameFinish || mFrame == mFrameResult) {
					// новая анимация
					if (mFrame != mFrameResult) {
						// начат новый переход в процессе еще не закончившегося
						mFrame = mFrameStart + (mFrameFinish - mFrameStart) * (frameFinish - mFrame) / (frameFinish - frameStart);
					} else {
						// обычный полный переход с начала
						mFrame = mFrameStart;
					}
				}
				mFrameResult = stateIndex < 0 ? 0 : mFramesStart[stateIndex];
				clip.addEventListener(Event.ENTER_FRAME, onEnterFrame);
				doStateStart();
				processFrame();
			} else if (stateIndex < 0) {
				// нет нового состояния, возможно это зацикленная анимация
				transIndex = mFramesName.indexOf(mState + ":" + mState);
				if (transIndex > 0) {
					mFrameStart = mFramesStart[transIndex];
					mFrameFinish = mFramesFinish[transIndex];
					mFrameResult = 0;
					mFrame = mFrameStart;
					clip.addEventListener(Event.ENTER_FRAME, onEnterFrame);
				} else {
					mFrameStart = 0;
					mFrameFinish = 0;
					mFrameResult = 1;
					mFrame = mFrameResult;
				}
				doStateStart();
				processFrame();
			} else {
				// переходов нет, существует только конечное состояние
				mFrameStart = 0;
				mFrameFinish = 0;
				mFrameResult = mFramesStart[stateIndex];
				mFrame = mFrameResult;
				doStateStart();
				processFrame();
			}
		}
		
		protected function onStateStart():void {
		}
		
		protected function onStateFinish():void {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработать и отобразить текущий кадр в соответствии с установками */
		private function processFrame():void {
			var frame:int;
			if (mFrame != mFrameResult) {
				// есть анимация, пересчитать ее текущую позицию
				var time:int = getTimer();
				frame = mFrame + (time - mFrameTime) * CGSetup.fpsMultiplier;
				if (mFrameResult > 0) {
					// однократная анимация
					if (frame >= mFrameFinish)
						// достигли конца анимации
						frame = mFrameResult;
				} else {
					// зацикленная анимация
					if (frame >= mFrameFinish)
						frame = mFrameStart + (frame - mFrameStart) % (mFrameFinish - mFrameStart);
				}
				if (frame != mFrame) {
					mFrame = frame;
					mFrameTime = time;
				}
			}
			if (!clip)
				return;
			if (mClipFrame == 0) {
				clip.visible = false;
				mClipFrame = mFrame;
				clip.gotoAndStop(mFrame);
				onFrameConstructed();
			} else if (mClipFrame != mFrame) {
				clip.visible = false;
				mClipFrame = mFrame;
				clip.addEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
				clip.gotoAndStop(mFrame);
			} else {
				onFrameConstructed();
			}
		}
		
		/** Обработчик покадровой анимации перехода состояний клипа */
		private function onEnterFrame(event:Event):void {
			processFrame();
		}
		
		/** Обработчик создания кадра при переходе */
		private function onFrameConstructed(event:Event = null):void {
			if (event != null) {
				var target:DisplayObject = event.target as DisplayObject;
				target.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			}
			doClipProcess();
			eventSend(new CGEvent(UPDATE));
			clip.visible = true;
			if (mFrame != mFrameResult)
				return;
			// достигнут результирующий кадр
			if (clip != null)
				clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			doStateFinish();
		}
		
		private function doStateStart():void {
			onStateStart();
			eventSend(new CGEventState(CGEventState.START, mState));
		}
		
		private function doStateFinish():void {
			onStateFinish();
			eventSend(new CGEventState(CGEventState.FINISH, mState));
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Текущее состояние элемента */
		protected var mState:String;
		
		/** Отрисованный кадр клипа */
		private var mClipFrame:int;
		
		/** Текущий кадр клипа */
		protected var mFrame:int;
		
		/** Время последнего обновления анимации перехода */
		protected var mFrameTime:int;
		
		/** Начальный кадр анимации перехода */
		protected var mFrameStart:int;
		
		/** Предельный кадр анимации перехода */
		protected var mFrameFinish:int;
		
		/** Результирующий кадр состояния по окончанию анимации перехода */
		protected var mFrameResult:int;
		
		/** Имена кадров */
		protected var mFramesName:Vector.<String>;
		
		/** Начальные кадры */
		protected var mFramesStart:Vector.<int>;
		
		/** Конечные кадры при переходах */
		protected var mFramesFinish:Vector.<int>;
		
	}

}
