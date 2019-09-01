package ui.common {
	
	/**
	 * Событие изменения поля ввода текста
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public class CGEventEdit extends CGEvent {
		
		/** Событие изменения текста */
		public static const CHANGE:String = "edit_change";
		
		/** Событие завершения ввода текста */
		public static const COMPLETE:String = "edit_complete";
		
		public function CGEventEdit(type:String, text:String = null) {
			super(type);
			m_text = text;
		}
		
		/** Текст поля ввода */
		public function get text():String {
			return m_text;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_text:String;
		
	}

}