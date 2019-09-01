package flicker.gui {
	
	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	/**
	 * Анимация интервалов таймлайна по именам и номерам шагов
	 * 
	 * @version  1.0.3
	 * @author   meps
	 */
	public class CGStepper extends CGContainer {
		
		public function CGStepper(src:* = null, name:String = null) {
			m_groupList = new Dictionary();
			m_step = 1;
			m_stepCurrent = m_step;
			m_clipFrame = 0;
			m_running = false;
			super(src, name);
			doState();
		}
		
		/** Имя используемой группы */
		public function get group():String {
			return m_group;
		}
		
		public function set group(val:String):void {
			if (val == m_group)
				return;
			m_group = val;
			m_groupCurrent = m_groupList[m_group];
			doState();
		}
		
		/** Текущий шаг в группе; при непосредственной смене шага любая текущая анимация прерывается */
		public function get step():int {
			return m_step;
		}
		
		public function set step(val:int):void {
			//if (val == m_step)
				//return;
			m_step = val;
			doState();
		}
		
		/** Вернуться в начало последовательности */
		public function gotoStart():void {
			m_step = 1;
			doState();
		}
		
		/** Наличие предыдущего шага;
		 * формальная проверка на то, что текущий шаг больше единицы */
		public function havePrev():Boolean {
			if (!m_groupCurrent)
				return false;
			return m_step > 1;
		}
		
		/** Перейти к предыдущему шагу без анимации;
		 * шаг вычисляется как -1 от текущего и если нет требуемого кадра, то
		 * клип скрывается со сцены */
		public function playPrev():void {
			if (!havePrev())
				return;
			--m_step;
			doState();
		}
		
		/** Наличие следующего шага;
		 * проверка на то, что текущий шаг не больше максимального в клипе */
		public function haveNext():Boolean {
			if (!m_groupCurrent)
				return false;
			return m_step < m_groupCurrent.maxStep;
		}
		
		/** Проанимировать до следующего шага;
		 * шаг вычисляется как +1 к текущему и если анимации не существует, то
		 * клип просто скрывается со сцены, но шаг предполагается измененным */
		public function playNext():void {
			// увеличивать шаг можно произвольно, т.к. при смене клипа или группы он может стать валидным
			++m_step;
			doState();
		}
		
		/** Текущее состояние анимации */
		public function get running():Boolean {
			return m_running;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		protected function doState():void {
			if (!clip)
				return;
			clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			if (!m_groupCurrent) {
				// скрыть клип, если группы не существует
				clip.visible = false;
				m_running = false;
				return;
			}
			m_frameStart = m_groupCurrent.getStart(m_step);
			m_frameEnd = m_groupCurrent.getEnd(m_step);
			if (m_frameStart == 0 || m_frameEnd == 0) {
				// скрыть клип, если неполный интервал
				clip.visible = false;
				m_running = false;
				return;
			}
			// начать анимацию перехода
			clip.visible = true;
			m_running = true;
			if (m_stepCurrent != m_step)
				m_frameTime = getTimer();
			m_stepCurrent = m_step;
			clip.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
			processFrame();
		}
		
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
				}
			} else {
				// клипа в новом состоянии нет, удалить старый
				doClipRemove();
				eventSend(new CGEvent(UPDATE));
			}
		}
		
		/** Зарегистрировать клип, подготовить данные по кадрам анимаций */
		override protected function onClipAppend(mc:MovieClip):void {
			m_clipFrame = 0;
			if (mc) {
				mc.stop();
				// собрать интервалы наименований кадров
				var labelList:Array/*FrameLabel*/ = (mc.scenes[0] as Scene).labels as Array/*FrameLabel*/;
				for each (var label:FrameLabel in labelList) {
					MATCH_NAME.lastIndex = 0;
					var execList:Array/*Object*/ = MATCH_NAME.exec(label.name);
					if (execList.length < 4)
						continue;
					var group:TStepperGroup;
					var id:String = execList[1];
					if (m_groupList.hasOwnProperty(id)) {
						group = m_groupList[id];
					} else {
						group = new TStepperGroup();
						m_groupList[id] = group;
					}
					var step:int = parseInt(execList[2]);
					if (step < 1)
						continue;
					var edge:String = execList[3];
					if (edge == MATCH_START)
						group.addStart(step, label.frame);
					else if (edge == MATCH_END)
						group.addEnd(step, label.frame);
				}
				m_groupCurrent = m_groupList[m_group];
			}
			doState();
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
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработать и отобразить текущий кадр */
		private function processFrame():void {
			var time:int = getTimer();
			m_frame = m_frameStart + (time - m_frameTime) * CGSetup.fpsMultiplier;
			if (m_frame > m_frameEnd)
				// достигли конца анимации
				m_frame = m_frameEnd;
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
			if (m_frame != m_frameEnd)
				return;
			// достигнут результирующий кадр
			if (clip)
				clip.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_group:String; // идентификатор текущей группы
		private var m_groupCurrent:TStepperGroup; // указатель на текущую группу
		private var m_groupList:Dictionary; // список всех групп
		private var m_step:int; // текущий шаг, счет от 1
		private var m_stepCurrent:int; // предыдущий шаг
		private var m_running:Boolean;
		private var m_frame:int // текущий кадр
		private var m_clipFrame:int; // отрисованный кадр клипа
		private var m_frameStart:int; // первый кадр анимации
		private var m_frameEnd:int; // последний кадр анимации
		private var m_frameTime:int; // время начала пересчета кадров для привязки анимации ко времени, а не к частоте кадров
		
		private static const MATCH_NAME:RegExp = /(\w+)_(\d+)_(start|end)$/g;
		private static const MATCH_START:String = "start";
		private static const MATCH_END:String = "end";
		
	}

}

/** Внутреннее хранилище рабочих интервалов одной группы */
internal class TStepperGroup {
	
	public function TStepperGroup() {
	}
	
	/** Максимальный номер шага */
	public function get maxStep():int {
		return m_maxStep;
	}
	
	/** Максимальный номер кадра */
	public function get maxFrame():int {
		return m_maxFrame;
	}
	
	/** Добавить начало интервала для некоторого шага */
	public function addStart(step:int, frame:int):void {
		check(step, frame);
		var index:int = m_steps.indexOf(step);
		if (index < 0) {
			index = m_steps.length
			m_steps[index] = step;
			m_end[index] = 0;
		}
		m_start[index] = frame;
	}
	
	/** Добавить конец интервала для некоторого шага */
	public function addEnd(step:int, frame:int):void {
		check(step, frame);
		var index:int = m_steps.indexOf(step);
		if (index < 0) {
			index = m_steps.length
			m_steps[index] = step;
			m_start[index] = 0;
		}
		m_end[index] = frame;
	}
	
	/** Получить начало интервала для шага */
	public function getStart(step:int):int {
		var index:int = m_steps.indexOf(step);
		if (index < 0)
			return 0;
		return m_start[index];
	}
	
	/** Получить конец интервала для шага */
	public function getEnd(step:int):int {
		var index:int = m_steps.indexOf(step);
		if (index < 0)
			return 0;
		return m_end[index];
	}
	
	////////////////////////////////////////////////////////////////////////////
	
	private function check(step:int, frame:int):void {
		if (step > m_maxStep)
			m_maxStep = step;
		if (frame > m_maxFrame)
			m_maxFrame = frame;
	}
	
	////////////////////////////////////////////////////////////////////////////
	
	private var m_maxStep:int = 1; // максимальный номер шага
	private var m_maxFrame:int = 1; // максимальный номер кадра
	private var m_steps:Vector.<int> = new Vector.<int>(); // соответствие шага и индекса
	private var m_start:Vector.<int> = new Vector.<int>(); // первые кадры интервалов
	private var m_end:Vector.<int> = new Vector.<int>(); // последние кадры интервалов
	
}
