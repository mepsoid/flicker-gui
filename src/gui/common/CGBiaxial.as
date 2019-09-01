package ui.common {
	
	import flash.display.MovieClip;
	import ui.common.CGContainer;
	
	/**
	 * Прототип контейнера для управления двухуровневым позиционированием на таймлайне
	 * 
	 * @version  1.0.3
	 * @author   meps
	 */
	public class CGBiaxial extends CGContainer {
		
		public function CGBiaxial(src:* = null, name:String = null) {
			m_heightContainer = new TContainer();
			m_widthContainers = new Vector.<TContainer>();
			super(src, name);
		}
		
		/** Задать полные размеры контейнера */
		public function size(width:int, height:int):void {
			if (height >= 0 && height != m_height) {
				// если изменилась высота, то перерисовать и высоту и последовательно ширину
				m_height = height;
				if (width >= 0)
					m_width = width;
				redrawHeight();
				notifyUpdate();
			} else if (width >= 0 && width != m_width) {
				// если изменилась ширина, то перерисовать только ширину
				m_width = width;
				redrawWidth();
				notifyUpdate();
			}
		}
		
		/** Высота контейнера */
		public function get height():int {
			return m_height;
		}
		
		public function set height(val:int):void {
			if (val < 0 || val == m_height)
				return;
			m_height = val;
			redrawHeight();
			notifyUpdate();
		}
		
		/** Ширина контейнера */
		public function get width():int {
			return m_width;
		}
		
		public function set width(val:int):void {
			if (val < 0 || val == m_width)
				return;
			m_width = val;
			redrawWidth()
			notifyUpdate();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			m_heightContainer = null;
			m_widthContainers = null;
			super.onDestroy();
		}
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			rebuildHeight();
			notifyUpdate();
		}
		
		override protected function onClipRemove(mc:MovieClip):void {
			super.onClipRemove(mc);
			rebuildHeight();
			notifyUpdate();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обновить корневой контейнер (пришел новый клип или обновление в предке) */
		private function rebuildHeight():void {
			m_heightContainer.clip = clip; // при необходимости обновится клип и будут пересчитаны интервалы кадров
			redrawHeight();
		}
		
		/** Обновить внутренние контейнеры (обновился корневой контейнер) */
		private function rebuildWidth():void {
			var index:int = 0;
			var len:int = m_widthContainers.length;
			while (index <= len) {
				var mc:MovieClip = MovieClip(objectFind(CONTAINER_PREFIX + index.toString()));
				if (index < len) {
					// для уже присутствующих контейнеров только обновить их клипы
					m_widthContainers[index].clip = mc;
				} else if (mc) {
					// вновь найденный контейнер добавить в список
					m_widthContainers[index] = new TContainer(mc);
					++len;
				}
				++index;
			}
			redrawWidth();
		}
		
		/** Перерисовать при изменении размера по высоте (корневой контейнер) */
		private function redrawHeight():void {
			var mc:MovieClip = m_heightContainer.clip;
			if (mc) {
				var frame:int = m_heightContainer.interpolate(m_height);
				if (frame) {
					mc.gotoAndStop(frame);
					mc.visible = true;
				} else {
					mc.visible = false;
				}
				rebuildWidth();
			}
		}
		
		/** Перерисовать при изменении размер по ширине (внутренние контейнеры) */
		private function redrawWidth():void {
			for each (var container:TContainer in m_widthContainers) {
				var mc:MovieClip = container.clip;
				if (mc) {
					var frame:int = container.interpolate(m_width);
					if (frame) {
						mc.gotoAndStop(frame);
						mc.visible = true;
					} else {
						mc.visible = false;
					}
				}
			}
		}
		
		/** Оповестить потомков о произошедших изменениях */
		private function notifyUpdate():void {
			// TODO возможно следует проверять на фактическое изменение списков
			// контейнеров и если его не было (например, контейнеры передвинулись
			// или изменили размер), то не вызывать событие обновления, все
			// элементы и так останутся на своих позициях в нужных состояниях
			eventSend(new CGEvent(UPDATE));
			doClipProcess();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_width:int;
		private var m_height:int;
		private var m_heightContainer:TContainer; // собственный контейнер по высоте
		private var m_widthContainers:Vector.<TContainer>; // список вложенных контейнеров по ширине
		
		private static const CONTAINER_PREFIX:String = ".container_";
		
	}

}

import flash.display.FrameLabel;
import flash.display.MovieClip;
import flash.display.Scene;

internal class TContainer {
	
	public function TContainer(mc:MovieClip = null) {
		m_frames = new Vector.<TSizeInterval>();
		if (mc)
			clip = mc;
	}
	
	/** Связанный с контейнером клип */
	public function get clip():MovieClip {
		return m_clip;
	}
	
	public function set clip(mc:MovieClip):void {
		if (m_clip === mc)
			// не обновлять тождественный клип
			return;
		m_clip = mc;
		m_frames.length = 0;
		if (mc) {
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
	}
	
	/** Определить номер кадра по значению размеров */
	public function interpolate(value:int):int {
		var maxSize:int = 0;
		var maxFrame:int = 0;
		var frame:int = 0;
		for (var index:int = m_frames.length - 1; index >= 0; --index) {
			var interval:TSizeInterval = m_frames[index];
			if (interval.inside(value)) {
				// если размер в интервале, то получить кадр для него
				frame = interval.interpolate(value);
				break;
			}
			if (maxSize < interval.maxSize) {
				// найти максимальный размер и соответствующий ему кадр
				maxSize = interval.maxSize;
				maxFrame = interval.maxFrame;
			}
		}
		if (frame == 0 && value >= maxSize)
			// для вышедших за максимальный размер взять максимальный кадр
			frame = maxFrame;
		return frame;
	}
	
	////////////////////////////////////////////////////////////////////////////
	
	private var m_clip:MovieClip; // связанный с контейнером текущий клип
	private var m_frames:Vector.<TSizeInterval>;
	
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
