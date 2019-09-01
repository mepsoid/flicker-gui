package flicker.gui {
	
	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	/**
	 * Прототип анимационных элементов, воспроизводящих анимацию
	 * 
	 * @version  1.0.3
	 * @author   meps
	 */
	public class CGAnimate extends CGContainer {
		
		public function CGAnimate(src:* = null, name:String = null) {
			m_framesList = new Vector.<int>();
			m_framesName = new Vector.<String>();
			super(src, name);
		}
		
		/** Запустить анимацию */
		public function start():void {
			m_frameCurrent = 1;
			m_running = true;
			m_frameTime = getTimer();
			doClipState();
		}
		
		/** Остановить анимацию */
		public function stop():void {
			m_running = false;
			doClipState();
		}
		
		////////////////////////////////////////////////////////////////////////
		
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
					doClipState();
					doClipProcess();
				}
			} else {
				// клипа в новом состоянии нет, удалить старый
				doClipRemove();
			}
			eventSend(new CGEvent(UPDATE));
		}
		
		/** Зарегистрировать клип, подготовить данные по кадрам анимаций */
		override protected function onClipAppend(mc:MovieClip):void {
			m_framesList.length = 0;
			m_framesName.length = 0;
			if (mc) {
				mc.stop();
				// собрать кадры анимации по именам
				var labelList:Array/*FrameLabel*/ = (mc.scenes[0] as Scene).labels as Array/*FrameLabel*/;
				m_frameFinish = mc.totalFrames; // последний используемый кадр
				for (var index:int = 0, length:int = labelList.length; index < length; ++index) {
					var label:FrameLabel = labelList[index] as FrameLabel;
					m_framesList.push(label.frame);
					m_framesName.push(label.name);
				}
			}
			doClipState();
		}
		
		/** Удалить регистрацию клипа */
		override protected function onClipRemove(mc:MovieClip):void {
			if (clip)
				clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		override protected function onDestroy():void {
			if (clip)
				clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			m_framesList = null;
			m_framesName = null;
			super.onDestroy();
		}
		
		/** Сменить текущее состояние клипа */
		protected function doClipState():void {
			if (!clip)
				return;
			clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			if (m_running)
				clip.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
			setCurrentFrame(m_frameCurrent);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Перейти на текущий кадр */
		private function setCurrentFrame(frame:int):void {
			if (frame == m_frameCurrent || !clip)
				return;
			m_frameTime = getTimer();
			try {
				clip.gotoAndStop(frame);
			} catch (error:Error) {
				clip.stop();
			}
			if (frame > m_frameCurrent) {
				// события для всех пройденных меток
				for (var index:int = 0, length:int = m_framesList.length; index < length; ++index) {
					var check:int = m_framesList[index];
					if (check > m_frameCurrent && check <= frame)
						eventSend(new CGEventState(CGEventState.LABEL, m_framesName[index]));
				}
			}
			m_frameCurrent = frame;
			clip.addEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
		}
		
		/** Обработчик создания кадра при переходе */
		private function onFrameConstructed(event:Event):void {
			var target:DisplayObject = event.target as DisplayObject;
			target.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			doClipProcess();
			eventSend(new CGEvent(UPDATE));
		}
		
		/** Обработчик покадровой анимации перехода состояний клипа */
		private function onEnterFrame(event:Event):void {
			var time:int = getTimer();
			var frame:int = m_frameCurrent + (time - m_frameTime) * CGSetup.fpsMultiplier;
			if (frame >= m_frameFinish) {
				// завершить анимацию
				m_running = false;
				frame = m_frameFinish;
				var target:DisplayObject = event.target as DisplayObject;
				target.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			setCurrentFrame(frame);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Флаг включенной анимации */
		private var m_running:Boolean;
		
		/** Время последней обработки кадра */
		private var m_frameTime:int;
		
		/** Текущий кадр */
		private var m_frameCurrent:int;
		
		/** Максимальный кадр */
		private var m_frameFinish:int;
		
		/** Последовательность кадров */
		private var m_framesList:Vector.<int>;
		
		/** Последовательность имен кадров */
		private var m_framesName:Vector.<String>;
		
	}

}