package flicker.gui {
	
	import flicker.utils.printClass;
	
	/**
	 * Групповой заголовок сетки для переключения сортировки по нему
	 * 
	 * @version  1.0.2
	 * @author   meps
	 */
	public class CGGridHeader extends CGButton {
		
		public function CGGridHeader(src:* = null, name:String = null, lab:String = null, val:* = null, app:CGGridHeader = null) {
			m_ascending = false;
			m_descending = false;
			m_value = val;
			m_sibling = this;
			super(src, name, lab);
			if (app)
				headerAppend(app);
		}
		
		/** Флаг сортировки по возрастанию */
		public function get ascending():Boolean {
			return m_ascending;
		}
		
		public function set ascending(val:Boolean):void {
			if (m_ascending == val)
				return;
			m_ascending = val;
			if (m_ascending) {
				m_descending = false;
				// сбросить выбор со всех прочих радио в группе
				var header:CGGridHeader = m_sibling;
				while (header!== this) {
					header.m_ascending = false;
					header.m_descending = false;
					header.doState();
					header = header.m_sibling;
				}
				doState();
				broadcastUpdate();
			} else {
				doState();
			}
		}
		
		/** Флаг сортировки по убыванию */
		public function get descending():Boolean {
			return m_descending;
		}
		
		public function set descending(val:Boolean):void {
			if (m_descending == val)
				return;
			m_descending = val;
			if (m_descending) {
				m_ascending = false;
				// сбросить выбор со всех прочих радио в группе
				var header:CGGridHeader = m_sibling;
				while (header!== this) {
					header.m_ascending = false;
					header.m_descending = false;
					header.doState();
					header = header.m_sibling;
				}
				doState();
				broadcastUpdate();
			} else {
				doState();
			}
		}
		
		/** Связанное с данным заголовком значение */
		public function get value():* {
			return m_value;
		}
		
		public function set value(val:*):void {
			m_value = val;
		}
		
		/** Экземпляр текущего выбранного заголовка */
		public function get headerSelected():CGGridHeader {
			var header:CGGridHeader = this;
			do {
				if (header.m_ascending || header.m_descending)
					return header;
				header = header.m_sibling;
			} while (header !== this)
			return null;
		}
		
		/** Добавить данный заголовок к группе других */
		public function headerAppend(header:CGGridHeader, val:* = null):void {
			if (val != null)
				m_value = val;
			if (m_sibling !== this)
				// если заголовок уже принадлежит другой группе, то сначала выйти из нее
				headerRemove();
			// дополнить кольцевой список
			m_sibling = header.m_sibling;
			header.m_sibling = this;
		}
		
		/** Удалить данный заголовок из группы других */
		public function headerRemove():void {
			if (m_sibling === this)
				return;
			// найти предыдущий заголовок в группе
			var header:CGGridHeader = m_sibling;
			while (header.m_sibling !== this)
				header = header.m_sibling;
			// изъять из кольцевого списка
			header.m_sibling = m_sibling;
			m_sibling = this;
		}
		
		override public function toString():String {
			return printClass(this, "over", "down", "enable", "ascending", "descending", "value");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			if (m_ascending)
				return super.doStateValue() + "_" + STATE_ASCENDING;
			if (m_descending)
				return super.doStateValue() + "_" + STATE_DESCENDING;
			return super.doStateValue() + "_" + STATE_REGULAR;
		}
		
		override protected function doButtonClick():void {
			// циклически переключать режимы сортировки на данной кнопке
			if (m_ascending) {
				ascending = false;
				descending = true;
			} else if (m_descending) {
				ascending = false;
				descending = false;
				broadcastUpdate();
			} else {
				descending = false;
				ascending = true;
			}
			super.doButtonClick();
		}
		
		override protected function onDestroy():void {
			m_sibling = null;
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Разослать событие выбора по всем заголовкам группы */
		private function broadcastUpdate():void {
			var header:CGGridHeader = this;
			do {
				header.eventSend(new CGEventSelect(CGEventSelect.SELECT, m_value));
				header = header.m_sibling;
			} while (header !== this)
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_value:*;
		private var m_ascending:Boolean;
		private var m_descending:Boolean;
		private var m_sibling:CGGridHeader;
		
		private static const STATE_ASCENDING:String  = "ascending";
		private static const STATE_DESCENDING:String = "descending";
		private static const STATE_REGULAR:String    = "regular";
		
	}

}