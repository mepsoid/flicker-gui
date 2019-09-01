package ui.common {
	
	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	/**
	 * Прототип элементов графического интерфейса
	 *
	 * @version  1.4.33
	 * @author   meps
	 */
	public class CGProto extends CGContainer {
		
		public function CGProto(src:* = null, name:String = null) {
			//log.write("#", "CGProto::constructor", src, name);
			m_frame = 0;
			m_clipFrame = 0;
			m_framesName = new Vector.<String>();
			m_framesStart = new Vector.<int>();
			m_framesFinish = new Vector.<int>();
			super(src, name);
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
			/*
			if (m_parent) {
				var mc:MovieClip = m_parent.objectFind(m_clipName) as MovieClip;
				if (mc != null) {
					if (!clip) {
						doClipAppend(mc);
					} else if (clip !== mc) {
						doClipRemove();
						doClipAppend(mc);
					}
					doClipState(m_state, false);
				} else {
					if (clip != null)
						doClipRemove();
				}
			} else if (clip != null) {
				doClipState(m_state, false);
			}
			doClipProcess();
			*/
			//trace(this, "update A");
			//eventSend(new CGEvent(UPDATE));
		}
		
		/** Обработчик смены состояния связанного родительского элемента */
		override protected function onClipParent():void {
			// найти по имени клип в родительском элементе
			var mc:MovieClip = m_parent.objectFind(m_clipName) as MovieClip;
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
				//trace(this, "update B");
				eventSend(new CGEvent(UPDATE));
			}
		}
		
		/** Зарегистрировать клип, подготовить данные по кадрам анимаций */
		override protected function onClipAppend(mc:MovieClip):void {
			m_clipFrame = 0;
			m_framesName.length = 0;
			m_framesStart.length = 0;
			m_framesFinish.length = 0;
			var state:String = doStateValue();
			if (mc) {
				mc.stop();
				//m_clipState = doStateValue();
				// собрать кадры анимации по именам
				var labelList:Array/*FrameLabel*/ = (mc.scenes[0] as Scene).labels as Array/*FrameLabel*/;
				var frameFinish:int = mc.totalFrames + 1; // последний используемый кадр
				var frameFirst:int = frameFinish; // первый используемый кадр
				for (var index:int = labelList.length - 1; index >= 0; --index) {
					var label:FrameLabel = labelList[index] as FrameLabel;
					var s:String = label.name;
					var j:int = m_framesName.indexOf(s);
					if (j < 0) {
						j = m_framesName.length;
						m_framesName[j] = s;
					}
					var frameLabel:int = label.frame;
					if (frameLabel < frameFirst) {
						// перемещать первый кадр только если он менялся
						if (frameFirst < frameFinish)
							frameFinish = frameFirst;
						frameFirst = frameLabel;
					}
					m_framesStart[j] = frameFirst;
					m_framesFinish[j] = frameFinish;
				}
			}
			doClipState(state, true);
		}
		
		/** Удалить регистрацию клипа */
		override protected function onClipRemove(mc:MovieClip):void {
			m_clipFrame = 0;
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
			m_framesName = null;
			m_framesStart = null;
			m_framesFinish = null;
			super.onDestroy();
		}
		
		/** Сменить состояние со старого на новое */
		protected function doClipState(stat:String, cont:Boolean = false):void {
			// TODO cont -- задел на будущее, чтобы можно было плавно переносить анимации при смене клипов в парентах
			//trace(this, "clipstate", stat, cont);
			var frame:int;
			if (!clip || !stat)
				return;
			clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			// проверить на наличие предыдущей анимации
			//if (m_frame != m_frameResult)
				//doStateFinish();
			//var transIndex:int = m_framesName.indexOf(m_clipState + ":" + stat);
			var transIndex:int = m_framesName.indexOf(m_state + ":" + stat);
			var stateIndex:int = m_framesName.indexOf(stat); // соответствующий новому состоянию индекс
			//m_clipState = stat;
			m_state = stat;
			m_frameTime = getTimer();
			if (m_clipFrame == 0) {
				// первоначальное состояние
				m_frameStart = 0;
				m_frameFinish = 0;
				m_frameResult = stateIndex < 0 ? 1 : m_framesStart[stateIndex];
				m_frame = m_frameResult;
				// несколько костылеобразно: ожидать следующего кадра для начальной инициализации клипа
				//clip.addEventListener(Event.ENTER_FRAME, onEnterFrame);
				//return;
				processFrame();
			} else if (transIndex >= 0) {
				// есть переход между состояниями
				var frameStart:int = m_frameStart;
				var frameFinish:int = m_frameFinish;
				m_frameStart = m_framesStart[transIndex];
				m_frameFinish = m_framesFinish[transIndex];
				if (frameStart != m_frameStart || frameFinish != m_frameFinish || m_frame == m_frameResult) {
					// новая анимация
					if (m_frame != m_frameResult) {
						// начат новый переход в процессе еще не закончившегося
						m_frame = m_frameStart + (m_frameFinish - m_frameStart) * (frameFinish - m_frame) / (frameFinish - frameStart);
						//trace(this, "continue", m_frame);
					} else {
						// обычный полный переход с начала
						m_frame = m_frameStart;
						//trace(this, "new", m_frame);
					}
				}
				m_frameResult = stateIndex < 0 ? 0 : m_framesStart[stateIndex];
				clip.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
				doStateStart();
				processFrame();
			} else if (stateIndex < 0) {
				// нет нового состояния, возможно это зацикленная анимация
				//transIndex = m_framesName.indexOf(m_clipState + ":" + m_clipState);
				transIndex = m_framesName.indexOf(m_state + ":" + m_state);
				if (transIndex > 0) {
					m_frameStart = m_framesStart[transIndex];
					m_frameFinish = m_framesFinish[transIndex];
					m_frameResult = 0;
					m_frame = m_frameStart;
					clip.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
				} else {
					m_frameStart = 0;
					m_frameFinish = 0;
					m_frameResult = 1;
					m_frame = m_frameResult;
				}
				doStateStart();
				processFrame();
			} else {
				// переходов нет, существует только конечное состояние
				m_frameStart = 0;
				m_frameFinish = 0;
				m_frameResult = m_framesStart[stateIndex];
				m_frame = m_frameResult;
				doStateStart();
				processFrame();
				
				/*
				if (m_state) {
					// перемотать клип на нужный кадр
					clip.visible = true;
					processFrame(frame);
				} else {
					// спрятать клип
					clip.visible = false;
					//doClipProcess();
					eventSend(new CGEvent(UPDATE));
				}
				doStateFinish();
				*/
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
			if (m_frame != m_frameResult) {
				// есть анимация, пересчитать ее текущую позицию
				var time:int = getTimer();
				frame = m_frame + (time - m_frameTime) * CGSetup.fpsMultiplier;
				if (m_frameResult > 0) {
					// однократная анимация
					if (frame >= m_frameFinish)
						// достигли конца анимации
						frame = m_frameResult;
				} else {
					// зацикленная анимация
					if (frame >= m_frameFinish)
						frame = m_frameStart + (frame - m_frameStart) % (m_frameFinish - m_frameStart);
				}
				if (frame != m_frame) {
					m_frame = frame;
					m_frameTime = time;
				}
			}
			if (!clip)
				return;
			if (m_clipFrame == 0) {
				m_clipFrame = m_frame;
				clip.gotoAndStop(m_frame);
				onFrameConstructed();
			} else if (m_clipFrame != m_frame) {
				m_clipFrame = m_frame;
				clip.addEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed, false, 0, true);
				clip.gotoAndStop(m_frame);
			} else {
				onFrameConstructed();
			}
		}
		
		/** Обработчик покадровой анимации перехода состояний клипа */
		private function onEnterFrame(event:Event):void {
			//trace(this, "enterframe");
			processFrame();
		}

		/** Обработчик создания кадра при переходе */
		private function onFrameConstructed(event:Event = null):void {
			//trace(this, "framecons", event, m_frameStart + ":" + m_frameFinish, m_frame + "-->" + m_frameResult);
			if (event != null) {
				var target:DisplayObject = event.target as DisplayObject;
				target.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			}
			doClipProcess();
			//trace(this, "update C");
			eventSend(new CGEvent(UPDATE));
			if (m_frame != m_frameResult)
				return;
			// достигнут результирующий кадр
			if (clip != null)
				clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			doStateFinish();
		}
		
		private function doStateStart():void {
			onStateStart();
			eventSend(new CGEventState(CGEventState.START, m_state));
		}
		
		private function doStateFinish():void {
			onStateFinish();
			eventSend(new CGEventState(CGEventState.FINISH, m_state));
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Текущее состояние элемента */
		protected var m_state:String;
		
		/** Текущее состояние клипа */
		//private var m_clipState:String;
		
		/** Отрисованный кадр клипа */
		private var m_clipFrame:int;
		
		/** Текущий кадр клипа */
		protected var m_frame:int;
		
		/** Время последнего обновления анимации перехода */
		protected var m_frameTime:int;
		
		/** Начальный кадр анимации перехода */
		protected var m_frameStart:int;
		
		/** Предельный кадр анимации перехода */
		protected var m_frameFinish:int;
		
		/** Результирующий кадр состояния по окончанию анимации перехода */
		protected var m_frameResult:int;
		
		/** Имена кадров */
		protected var m_framesName:Vector.<String>;
		
		/** Начальные кадры */
		protected var m_framesStart:Vector.<int>;
		
		/** Конечные кадры при переходах */
		protected var m_framesFinish:Vector.<int>;
		
	}

}
