package ui.common {
	
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	/**
	 * Редактируемое поле ввода
	 * 
	 * @version  1.1.8
	 * @author   meps
	 */
	public class CGEdit extends CGInteractive {
		
		public function CGEdit(src:* = null, name:String = null) {
			m_enable = true;
			m_focus = false;
			m_value = "";
			m_last = "";
			m_prompt = "";
			super(src, name);
		}
		
		/** Активность поля ввода */
		public function get enable():Boolean {
			return m_enable;
		}
		
		public function set enable(val:Boolean):void {
			if (val == m_enable)
				return;
			m_enable = val;
			doState();
			if (m_field) {
				m_field.type = m_enable ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
				m_field.selectable = m_enable;
			}
		}
		
		/** Значение поля ввода */
		public function get value():String {
			if (m_focus && m_field)
				return m_field.text;
			return m_value;
		}
		
		public function set value(val:String):void {
			if (val == m_value)
				return;
			m_value = val ? val : "";
			m_last = m_value;
			redrawField();
			eventSend(new CGEventEdit(CGEventEdit.COMPLETE, m_value));
		}
		
		/** Сбросить поле ввода */
		public function clear():void {
			if (!m_value)
				return;
			m_value = "";
			m_last = "";
			redrawField();
			eventSend(new CGEventEdit(CGEventEdit.COMPLETE, m_value));
		}
		
		/** Приглашение для ввода текста */
		public function get prompt():String {
			return m_prompt;
		}
		
		public function set prompt(val:String):void {
			if (val == m_prompt)
				return;
			m_prompt = val ? val : "";
			redrawField();
		}
		
		/** Установить фокус ввода на поле */
		public function focus():void {
			if (m_field && m_field.stage.focus !== m_field)
				m_field.stage.focus = m_field;
		}
		
		/** Снять фокус ввода с поля */
		public function unfocus():void {
			if (m_field && m_field.stage.focus === m_field)
				m_field.stage.focus = null;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			if (!m_enable)
				return DISABLE_STATE;
			if (m_focus)
				return EDIT_STATE;
			return m_over ? OVER_STATE : OUT_STATE;
		}
		
		override protected function onClipProcess():void {
			super.onClipProcess();
			var field:TextField = objectFind(FIELD_ID) as TextField;
			//trace("===", field === m_field);
			if (field !== m_field) {
				// отписаться от событий старого поля
				if (m_field) {
					if (m_field.stage && m_field.stage.focus === m_field)
						m_field.stage.focus = null;
					m_field.removeEventListener(FocusEvent.FOCUS_IN, onFieldFocus);
					m_field.removeEventListener(FocusEvent.FOCUS_OUT, onFieldUnfocus);
					m_field.removeEventListener(Event.CHANGE, onFieldChange);
					m_field.removeEventListener(KeyboardEvent.KEY_DOWN, onFieldKey);
					m_field = null;
				}
				//m_field = field;
				// настроить новое поле и подписаться на его события
				if (field) {
					field.type = m_enable ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
					field.selectable = m_enable;
					field.tabEnabled = false;
					field.addEventListener(FocusEvent.FOCUS_IN, onFieldFocus, false, 0, true);
					field.addEventListener(FocusEvent.FOCUS_OUT, onFieldUnfocus, false, 0, true);
					field.addEventListener(Event.CHANGE, onFieldChange, false, 0, true);
					field.addEventListener(KeyboardEvent.KEY_DOWN, onFieldKey, false, 0, true);
					//trace("onClipProcess", "focus:", m_focus, "already:", m_field.stage.focus === m_field);
				}
			}
			if (!field) {
				// поле не найдено
				m_field = null;
				return;
			}
			// отмасштабировать относительно предка
			if (m_field !== field) {
				m_field = field;
				m_fieldWidth = m_field.width;
				m_fieldHeight = m_field.height;
			}
			var parent:DisplayObjectContainer = m_field.parent;
			var matrix:Matrix = parent.transform.matrix;
			var coeffA:Number = matrix.a;
			var coeffD:Number = matrix.d;
			var width:int = m_fieldWidth * coeffA;// m_field.width * coeffA;
			var height:int = m_fieldHeight * coeffD;// m_field.height * coeffD;
			matrix = m_field.transform.matrix;
			//trace("1", parent.name, width + "x" + height, matrix, coeffA + ":" + coeffD, m_field.getBounds(parent));
			matrix.a = 1.0 / coeffA;
			matrix.d = 1.0 / coeffD;
			m_field.width = width;
			m_field.height = height;
			m_field.transform.matrix = matrix;
			//trace("2", m_field.width + "x" + m_field.height, matrix, coeffA + ":" + coeffD, m_field.getBounds(parent));
			//m_field.border = true;
			if (m_focus && m_field.stage)
				// при необходимости установить фокус на поле
				m_field.stage.focus = m_field;
			redrawField();
		}
		
		override protected function onDestroy():void {
			if (m_field) {
				m_field.removeEventListener(FocusEvent.FOCUS_IN, onFieldFocus);
				m_field.removeEventListener(FocusEvent.FOCUS_OUT, onFieldUnfocus);
				m_field.removeEventListener(Event.CHANGE, onFieldChange);
				m_field.removeEventListener(KeyboardEvent.KEY_DOWN, onFieldKey);
				m_field = null;
			}
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработчик получения фокуса полем ввода */
		private function onFieldFocus(event:FocusEvent):void {
			if (!m_enable)
				return;
			// сохранить текущее сообщение для возможности к нему вернуться
			//trace("onFieldFocus", "focus:", m_focus, "already:", m_field.stage.focus === m_field);
			m_last = m_value;
			if (!m_focus) {
				m_focus = true;
				doState();
			}
			redrawField();
		}
		
		/** Обработчик потери фокуса полем ввода */
		private function onFieldUnfocus(event:FocusEvent):void {
			if (!m_enable)
				return;
			//trace("onFieldUnfocus", "focus:", m_focus, "already:", m_field.stage.focus === m_field);
			if (m_focus) {
				m_focus = false;
				doState();
			}
			redrawField();
			//eventSend(new CGEventEdit(CGEventEdit.COMPLETE, m_value));
		}
		
		/** Обработчик изменения текста в поле ввода сообщения */
		private function onFieldChange(event:Event):void {
			if (!m_enable)
				return;
			m_value = m_field.text;
			eventSend(new CGEventEdit(CGEventEdit.CHANGE, value));
		}
		
		/** Обработчик нажатия клавиш в поле ввода сообщения */
		private function onFieldKey(event:KeyboardEvent):void {
			if (!m_enable)
				return;
			switch (event.keyCode) {
				case Keyboard.ESCAPE:
					// сбросить сообщение и снять фокус с поля ввода
					m_value = m_last;
					redrawField();
					if (m_field.stage.focus === m_field)
						m_field.stage.focus = null;
					break;
				case Keyboard.ENTER:
					// подтверждение текста
					m_value = m_field.text;
					m_last = m_value;
					redrawField();
					if (m_field.stage.focus === m_field)
						m_field.stage.focus = null;
					// прервать обработку перевода строки
					event.stopPropagation();
					eventSend(new CGEventEdit(CGEventEdit.COMPLETE, m_value));
					break;
			}
		}
		
		/** Вывод текущего состояния в поле ввода */
		private function redrawField():void {
			if (!m_field)
				return;
			m_field.text = m_value || m_focus ? m_value : (m_prompt ? m_prompt : "");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Активность поля ввода */
		private var m_enable:Boolean;
		
		/** Флаг фокуса ввода */
		private var m_focus:Boolean;
		
		/** Значение поля ввода */
		private var m_value:String;
		
		/** Последнее активное значение поля ввода, к нему приводится поле в случае отказа */
		private var m_last:String;
		
		/** Текст приглашения к вводу */
		private var m_prompt:String;
		
		/** Используемое текстовое поле */
		private var m_field:TextField;
		
		/** Закешированные точные размеры текстового поля */
		private var m_fieldWidth:Number, m_fieldHeight:Number;
		
		private static const OUT_STATE:String = "out";
		private static const OVER_STATE:String = "over";
		private static const EDIT_STATE:String = "edit";
		private static const DISABLE_STATE:String = "disable";
		
		private static const FIELD_ID:String = ".edit";
		
	}

}