package ui.common {
	
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.events.Event;
	import flash.utils.setTimeout;
	import services.printClass;
	import services.printTimestamp;
	
	/**
	 * Прототип подстраивающегося под размеры контейнера
	 * 
	 * @version  1.0.8
	 * @author   meps
	 */
	public class CGResizable extends CGContainer {
		
		public function CGResizable(src:* = null, name:String = null, _size:int = 0) {
			m_frame = 0;
			m_frames = new Vector.<TSizeInterval>();
			super(src, name);
			size = _size;
		}
		
		/** Размер, под который подстраивается контейнер */
		public function get size():int { return m_size; }
		
		public function set size(val:int):void {
			// FIXME оптимизировать;
			// сейчас у вложенных масштабируемых контейнеров обновление размера
			// внешнего не приводит к полноценной перерисовке нижнего
			if (val < 0)// || val == m_size)
				return;
			m_size = val;
			doState();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onClipParent():void {
			// найти по имени клип в родительском элементе
			var mc:MovieClip = m_parent.objectFind(m_clipName) as MovieClip;
			//trace(printTimestamp(), "CGResizable::onClipParent", printClass(this));
			if (mc) {
				// найден соответствующий клип
				if (mc === clip) {
					// сам клип сохранился, просто обновить его
					//trace("same clip", printClass(clip, "name", "currentFrame", "totalFrames"));
					doClipProcess();
				} else {
					// полностью заменить клип
					//trace("update clip", printClass(mc, "name", "currentFrame", "totalFrames"), "-->", printClass(clip, "name", "currentFrame", "totalFrames"));
					doClipRemove();
					doClipAppend(mc);
					// FIXME скрыты два вызова, т.к. при добавлении клипа они все равно будут выполнены
					//doState();
					//doClipProcess();
				}
			} else {
				// клипа в новом состоянии нет, удалить старый
				//trace("remove clip", printClass(clip, "name", "currentFrame", "totalFrames"));
				doClipRemove();
				eventSend(new CGEvent(UPDATE));
			}
		}
		
		/** Заполнение дескрипторов кадров */
		override protected function onClipAppend(mc:MovieClip):void {
			m_frames.length = 0;
			if (mc) {
				mc.stop();
				// собрать кадры анимации по именам
				var labelList:Array/*FrameLabel*/ = (mc.scenes[0] as Scene).labels as Array/*FrameLabel*/;
				var frameFinish:int = mc.totalFrames + 1; // последний используемый кадр
				var frameFirst:int = frameFinish; // первый используемый кадр
				for (var index:int = labelList.length - 1; index >= 0; --index) {
					var label:FrameLabel = labelList[index] as FrameLabel;
					var name:String = label.name;
					var pos:int = name.indexOf(":");
					var valueMin:int = parseInt(name.substring(0, pos));
					var valueMax:int = parseInt(name.substring(pos + 1));
					var frameCurrent:int = label.frame;
					if (frameCurrent < frameFirst) {
						// перемещать первый кадр только если он менялся
						if (frameFirst < frameFinish)
							frameFinish = frameFirst;
						frameFirst = frameCurrent;
					}
					var interval:TSizeInterval = new TSizeInterval(frameFirst, frameFinish, valueMin, valueMax);
					m_frames.push(interval);
				}
			}
			//trace(printTimestamp(), "CGResizable::onClipAppend", printClass(this), printClass(mc, "name", "currentFrame", "totalFrames"));
			m_frame = 0;
			doState();
		}
		
		override protected function onDestroy():void {
			if (clip)
				clip.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			m_frames = null;
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Поиск подходящего кадра для заданного размера и его установка */
		private function doState():void {
			var maxSize:int = 0;
			var maxFrame:int = 0;
			var frame:int = 0;
			for (var index:int = m_frames.length - 1; index >= 0; --index) {
				var interval:TSizeInterval = m_frames[index];
				if (interval.inside(m_size)) {
					// если размер в интервале, то получить кадр для него
					frame = interval.interpolate(m_size);
					break;
				}
				if (maxSize < interval.maxSize) {
					// найти максимальный размер и соответствующий ему кадр
					maxSize = interval.maxSize;
					maxFrame = interval.maxFrame;
				}
			}
			if (frame == 0 && m_size >= maxSize)
				// для вышедших за максимальный размер взять максимальный кадр
				frame = maxFrame;
			//trace(printTimestamp(), "CGResizable::doState", printClass(this), printClass(clip, "name", "currentFrame", "totalFrames"), frame, "-->", m_frame);
			// FIXME оптимизировать;
			// если происходит обновление родительского контейнера, то вложенный
			// масштабируемый должен быть перерисован и установлен в соответствующий
			// кадр, однако он считает, что изменений кадра не происходило и можно
			// не обновляться
			//if (frame == m_frame)
				// ничего не поменялось
				//return;
			m_frame = frame;
			if (clip != null) {
				if (m_frame > 0) {
					clip.visible = true;
					if (m_frame != clip.currentFrame) {
						//trace("different frame", printClass(this), printClass(clip, "name", "currentFrame", "totalFrames"), m_frame, "-->", clip.currentFrame);
						clip.addEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
						clip.gotoAndStop(m_frame);
					} else {
						//trace("same frame", printClass(this), printClass(clip, "name", "currentFrame", "totalFrames"));
						eventSend(new CGEvent(UPDATE));
					}
				} else {
					clip.visible = false;
				}
			} else {
				//trace("empty clip", printClass(this));
				//eventSend(new CGEvent(UPDATE));
			}
			//trace(printTimestamp(), "continue", printClass(this), printClass(clip, "name", "currentFrame", "totalFrames"));
		}
		
		/** Обработчик создания кадра при переходе */
		private function onFrameConstructed(event:Event):void {
			//trace(printTimestamp(), "CGResizable::onFrameConstructed", printClass(this), printClass(clip, "name", "currentFrame", "totalFrames"));
			event.target.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			if (clip && clip.currentFrame != m_frame) {
				//trace("different frames", m_frame, "-->", clip.currentFrame);
				clip.gotoAndStop(m_frame);
			}
			doClipProcess();
			eventSend(new CGEvent(UPDATE));
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_size:int; // заданный размер
		private var m_frame:int; // текущий кадр
		private var m_frames:Vector.<TSizeInterval>;
		
	}

}

/** Дескриптор интервалов анимации для позиционирования */
internal class TSizeInterval {
	
	public function TSizeInterval(_start:int, _finish:int, _min:int, _max:int) {
		m_frameStart = _start;
		m_frameFinish = _finish;
		m_sizeMin = _min;
		m_sizeMax = _max;
	}
	
	public function inside(value:int):Boolean {
		return m_sizeMin <= value && value < m_sizeMax;
	}
	
	public function interpolate(value:int):int {
		return m_frameStart + (value - m_sizeMin) * (m_frameFinish - m_frameStart - 1) / (m_sizeMax - m_sizeMin);		
	}
	
	public function get maxSize():int {
		return m_sizeMax;
	}
	
	public function get maxFrame():int {
		return m_frameFinish;
	}
	
	private var m_frameStart:int; // первый кадр
	private var m_frameFinish:int; // последний кадр
	private var m_sizeMin:int; // минимальное значение размера
	private var m_sizeMax:int; // максимальное значение размера
	
}