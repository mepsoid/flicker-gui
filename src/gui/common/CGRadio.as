package ui.common {
	
	import services.printClass;
	
	/**
	 * Объединяемая в группы радиокнопка 
	 * 
	 * @version  1.0.9
	 * @author   meps
	 */
	public class CGRadio extends CGButton {
		
		public function CGRadio(src:* = null, name:String = null, lab:String = null, val:* = null, app:CGRadio = null) {
			m_select = false;
			m_value = val;
			m_sibling = this;
			super(src, name, lab);
			if (app)
				radioAppend(app);
		}
		
		/** Флаг включенного состояния радиокнопки */
		public function get select():Boolean {
			return m_select;
		}
		
		public function set select(val:Boolean):void {
			if (m_select == val)
				return;
			m_select = val;
			doState();
			if (m_select) {
				// сбросить выбор со всех прочих радио в группе
				var radio:CGRadio = m_sibling;
				while (radio !== this) {
					radio.m_select = false;
					radio.doState();
					radio = radio.m_sibling;
				}
				broadcastSelect();
			}
			onSelect();
		}
		
		/** Циклически переключить выбранную радиокнопку на следующую; если
		    никакая еще не выбрана, сделать текущую активной */
		public function selectNext():void {
			var radio:CGRadio = this;
			do {
				if (radio.m_select) {
					radio.m_sibling.select = true;
					return;
				}
				radio = radio.m_sibling;
			} while (radio !== this)
			select = true;
		}
		
		/** Циклически переключить выбранную радиокнопку на предыдущую; если
		    никакая еще не выбрана, сделать текущую активной */
		public function selectPrev():void {
			var radio:CGRadio = this;
			do {
				if (radio.m_sibling.m_select) {
					radio.select = true;
					return;
				}
				radio = radio.m_sibling;
			} while (radio !== this)
			select = true;
		}
		
		/** Связанное с данной кнопкой значение */
		public function get value():* {
			return m_value;
		}
		
		public function set value(val:*):void {
			m_value = val;
		}
		
		/** Текущее выбранное в группе значение */
		public function get valueSelected():* {
			var radio:CGRadio = this;
			do {
				if (radio.m_select)
					return radio.m_value;
				radio = radio.m_sibling;
			} while (radio !== this)
			return null;
		}
		
		public function set valueSelected(val:*):void {
			var radio:CGRadio =  this;
			do {
				if (radio.m_value == val) {
					radio.select = true;
					return;
				}
				radio = radio.m_sibling;
			} while (radio !== this)
		}
		
		/** Экземпляр текущей выбранной радиокнопки */
		public function get radioSelected():CGRadio {
			var radio:CGRadio = this;
			do {
				if (radio.m_select)
					return radio;
				radio = radio.m_sibling;
			} while (radio !== this)
			return null;
		}
		
		/** Добавить данную радиокнопку к группе других */
		public function radioAppend(radio:CGRadio, val:* = null):void {
			if (val != null)
				m_value = val;
			if (m_sibling !== this)
				// если радиокнопка уже принадлежит другой группе, то сначала выйти из нее
				radioRemove();
			// дополнить кольцевой список
			m_sibling = radio.m_sibling;
			radio.m_sibling = this;
		}
		
		/** Удалить данную радиокнопку из группы других */
		public function radioRemove():void {
			if (m_sibling === this)
				return;
			// найти предыдущую кнопку в группе
			var radio:CGRadio = m_sibling;
			while (radio.m_sibling !== this)
				radio = radio.m_sibling;
			// изъять из кольцевого списка
			radio.m_sibling = m_sibling;
			m_sibling = this;
		}
		
		override public function toString():String {
			return printClass(this, "over", "down", "enable", "select", "value");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			return super.doStateValue() +
				"_" +
				(m_select ? STATE_SELECT : STATE_REGULAR);
		}
		
		override protected function doButtonClick():void {
			select = true;
			super.doButtonClick();
		}
		
		override protected function onDestroy():void {
			radioRemove();
			m_value = null;
			m_sibling = null;
			super.onDestroy();
		}
		
		protected function onSelect():void {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Разослать событие выбора по всем радиокнопкам группы */
		private function broadcastSelect():void {
			var radio:CGRadio = this;
			do {
				radio.eventSend(new CGEventSelect(CGEventSelect.SELECT, m_value));
				radio = radio.m_sibling;
			} while (radio !== this)
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_select:Boolean;
		private var m_value:*;
		private var m_sibling:CGRadio; // кольцевой однонаправленный список
		
		private static const STATE_SELECT:String  = "select";
		private static const STATE_REGULAR:String = "regular";
		
	}

}
