package ui.common {
	
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.events.Event;
	
	/**
	 * Прототип подстраивающегося под размеры контейнера
	 * 
	 * @version  1.0.4
	 * @author   meps
	 */
	public class CGResizable extends CGContainer {
		
		public function CGResizable(src:* = null, name:String = null, _size:int = 0) {
			m_frames = new Vector.<TSizeInterval>();
			super(src, name);
			size = _size;
		}
		
		/** Размер, под который подстраивается контейнер */
		public function get size():int { return m_size; }
		
		public function set size(val:int):void {
			if (val < 0 || val == m_size)
				return;
			m_size = val;
			doState();
		}
		
		////////////////////////////////////////////////////////////////////////
		
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
			doState();
		}
		
		override protected function onClipParent():void {
			// найти по имени клип в родительском элементе
			var mc:MovieClip = m_parent.objectFind(m_clipName) as MovieClip;
			//trace(printClass(this), "::onClipParent", m_clipName, printClass(mc));
			if (mc) {
				// найден соответствующий клип
				if (mc === clip) {
					// сам клип сохранился, просто обновить его
					doClipProcess();
				} else {
					// полностью заменить клип
					doClipRemove();
					doClipAppend(mc);
					doState();
					doClipProcess();
				}
			} else {
				// клипа в новом состоянии нет, удалить старый
				doClipRemove();
			}
			//trace(this, "update 1");
			eventSend(new CGEvent(UPDATE));
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
			var frame:int = 0;
			for (var index:int = m_frames.length - 1; index >= 0; --index) {
				var interval:TSizeInterval = m_frames[index];
				if (interval.min <= m_size && m_size < interval.max) {
					frame = interval.start + (m_size - interval.min) * (interval.finish - interval.start) / (interval.max - interval.min);
					break;
				}
			}
			m_frame = frame;
			if (clip != null) {
				if (frame > 0) {
					clip.visible = true;
					if (frame != clip.currentFrame) {
						clip.addEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed, false, 0, true);
						clip.gotoAndStop(frame);
					}
				} else {
					clip.visible = false;
				}
			} else {
				//trace(this, "update 2");
				eventSend(new CGEvent(UPDATE));
			}
		}
		
		/** Обработчик создания кадра при переходе */
		private function onFrameConstructed(event:Event):void {
			event.target.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			doClipProcess();
			//trace(this, "update 3");
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
	
	public var start:int; // первый кадр
	public var finish:int; // последний кадр
	public var min:int; // минимальное значение размера
	public var max:int; // максимальное значение размера
	
	public function TSizeInterval(_start:int, _finish:int, _min:int, _max:int) {
		start = _start;
		finish = _finish;
		min = _min;
		max = _max;
	}
	
}