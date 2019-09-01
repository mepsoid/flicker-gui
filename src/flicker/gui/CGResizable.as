package flicker.gui {
	
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.events.Event;
	
	/**
	 * Прототип подстраивающегося под размеры контейнера
	 *
	 * @version  1.0.9
	 * @author   meps
	 */
	public class CGResizable extends CGContainer {
		
		public function CGResizable(src:* = null, name:String = null, _size:int = 0) {
			mFrame = 0;
			mFrames = new Vector.<TSizeInterval>();
			super(src, name);
			size = _size;
		}
		
		/** Размер, под который подстраивается контейнер */
		public function get size():int { return mSize; }
		
		public function set size(val:int):void {
			// FIXME оптимизировать;
			// сейчас у вложенных масштабируемых контейнеров обновление размера
			// внешнего не приводит к полноценной перерисовке нижнего
			if (val < 0)// || val == m_size)
				return;
			mSize = val;
			doState();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onClipParent():void {
			// найти по имени клип в родительском элементе
			var mc:MovieClip = mParent.objectFind(mClipName) as MovieClip;
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
			mFrames.length = 0;
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
					mFrames.push(interval);
				}
			}
			//trace(printTimestamp(), "CGResizable::onClipAppend", printClass(this), printClass(mc, "name", "currentFrame", "totalFrames"));
			mFrame = 0;
			doState();
		}
		
		override protected function onDestroy():void {
			if (clip)
				clip.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			mFrames = null;
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Поиск подходящего кадра для заданного размера и его установка */
		private function doState():void {
			var maxSize:int = 0;
			var maxFrame:int = 0;
			var frame:int = 0;
			for (var index:int = mFrames.length - 1; index >= 0; --index) {
				var interval:TSizeInterval = mFrames[index];
				if (interval.inside(mSize)) {
					// если размер в интервале, то получить кадр для него
					frame = interval.interpolate(mSize);
					break;
				}
				if (maxSize < interval.maxSize) {
					// найти максимальный размер и соответствующий ему кадр
					maxSize = interval.maxSize;
					maxFrame = interval.maxFrame;
				}
			}
			if (frame == 0 && mSize >= maxSize)
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
			mFrame = frame;
			if (clip != null) {
				if (mFrame > 0) {
					clip.visible = true;
					if (mFrame != clip.currentFrame) {
						//trace("different frame", printClass(this), printClass(clip, "name", "currentFrame", "totalFrames"), m_frame, "-->", clip.currentFrame);
						clip.addEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
						clip.gotoAndStop(mFrame);
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
			if (clip && clip.currentFrame != mFrame) {
				//trace("different frames", m_frame, "-->", clip.currentFrame);
				clip.gotoAndStop(mFrame);
			}
			doClipProcess();
			eventSend(new CGEvent(UPDATE));
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mSize:int; // заданный размер
		private var mFrame:int; // текущий кадр
		private var mFrames:Vector.<TSizeInterval>;
		
	}

}

/** Дескриптор интервалов анимации для позиционирования */
internal class TSizeInterval {
	
	public function TSizeInterval(start:int, finish:int, min:int, max:int) {
		mFrameStart = start;
		mFrameFinish = finish;
		mSizeMin = min;
		mSizeMax = max;
	}
	
	public function inside(value:int):Boolean {
		return mSizeMin <= value && value < mSizeMax;
	}
	
	public function interpolate(value:int):int {
		return mFrameStart + (value - mSizeMin) * (mFrameFinish - mFrameStart - 1) / (mSizeMax - mSizeMin);
	}
	
	public function get maxSize():int {
		return mSizeMax;
	}
	
	public function get maxFrame():int {
		return mFrameFinish;
	}
	
	private var mFrameStart:int; // первый кадр
	private var mFrameFinish:int; // последний кадр
	private var mSizeMin:int; // минимальное значение размера
	private var mSizeMax:int; // максимальное значение размера
	
}