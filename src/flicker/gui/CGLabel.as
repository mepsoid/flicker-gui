package flicker.gui {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;
	import flash.utils.Dictionary;
	
	/**
	 * Прототип основных действий над элементами графического интерфейса
	 * 
	 * @version  1.1.20
	 * @author   meps
	 */
	public class CGLabel extends CGProto {
		
		public function CGLabel(src:* = null, name:String = null) {
			m_texts = new Dictionary();
			m_textsAuto = new Dictionary();
			//log.write("#", "construct CGLabel", src, name);
			super(src, name);
		}
		
		/** Чтение текстового поля */
		public function textGet(id:String):String {
			if (!m_texts.hasOwnProperty(id))
				return null;
			return m_texts[id];
		}
		
		/** Запись текстового поля */
		public function textSet(text:String, id:String, auto:Boolean = false):void {
			m_textsAuto[id] = auto;
			if (m_texts.hasOwnProperty(id))
				if (m_texts[id] == text)
					// содержание текста не менялось
					return;
			m_texts[id] = text;
			// обновлять только затронутые изменением текстовые поля
			var tf:TextField = objectFind(id) as TextField;
			if (tf)
				onTextUpdate(tf, id, m_texts[id]);
			eventSend(new CGEventChange(CGEventChange.TEXT, id));
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onDestroy():void {
			m_texts = null;
			m_textsAuto = null;
			super.onDestroy();
		}
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			updateAll();
		}
		
		override protected function onClipProcess():void {
			super.onClipProcess();
			updateAll();
		}
		
		/** Стандартный обработчик каждого обновления текстового поля */
		protected function onTextUpdate(field:TextField, textId:String, textValue:String):void {
			doTextRefit(field, textValue, m_textsAuto[textId]);
		}
		
		/** Обновление всех текстовых полей и иконок */
		protected function updateAll():void {
			var id:String;
			// если текст и иконки не менялись -- обновить все тексты
			for (id in m_texts) {
				var tf:TextField = objectFind(id) as TextField;
				if (tf)
					onTextUpdate(tf, id, m_texts[id]);
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private function onTextChange(e:Event):void {
			//log.write("onTextUpdate", (e.target as TextField).name, (e.target as TextField).text);
			var n:String = (e.target as TextField).name;
			if (n) {
				m_texts[n] = (e.target as TextField).text;
				eventSend(new CGEventChange(CGEventChange.TEXT, n));
			}
		}
		
		private function doTextRefit(tf:TextField, tx:String, auto:Boolean):void {
			var f:TextFormat = tf.getTextFormat();
			tf.mouseEnabled = false;// !auto; // запретить взаимодействие с автоматически выравнивающимися текстовыми полями
			tf.defaultTextFormat = f;
			if (tx != null)
				tf.text = tx;
			tf.removeEventListener(Event.CHANGE, onTextChange, false);
			tf.addEventListener(Event.CHANGE, onTextChange, false, 0, true);
			if (!tx)
				// если текст не задан
				return;
			if (!auto)
				return;
			// автовыравнивание текста, сохранить и сбросить фильтры до выравнивания
			var fl:Array/*BitmapFilter*/ = tf.filters;
			tf.filters = null;
			var w:Number = tf.width - 4;
			var tw:Number = tf.textWidth;
			var h:Number = tf.height - 4;
			var th:Number = tf.textHeight;
			var fs:Number = f.size as Number;
			f.blockIndent = 0;
			if (tw > w || th > h) {
				// если реальная ширина или высота больше, уменьшать шрифт, до полного влезания текста в область
				while (fs > 1 && (tw > w || th > h)) {
					--fs;
					f.size = fs;
					tf.defaultTextFormat = f;
					tf.text = tf.text;
					tw = tf.textWidth;
					th = tf.textHeight;
				}				
			} else if (tw < w && th < h) {
				// ... иначе, увеличивать шрифт до максимального заполнения на всю ширину
				var b:Boolean = true;
				while (b) {
					if (tw < w && th < h) {
						// размер недостаточный
						++fs;
					} else if (tw > w || th > h) {
						// превысили размер, сделать один шаг назад и завершить итерации
						--fs;
						b = false;
					} else {
						// равенство размеров
						break;
					}
					f.size = fs;
					tf.defaultTextFormat = f;
					tf.text = tf.text;
					tw = tf.textWidth;
					th = tf.textHeight;
				}
			}
			if (th < h) {
				// вертикальное выравнивание; создать вертикальный отступ за счет перевода в начале строки
				var m:TextLineMetrics = tf.getLineMetrics(0);
				var t:Number = Number(f.size) * (h - th) * 0.5 / m.height;
				if (t > 1) {
					f.size = t;
					tf.text = "\n" + tf.text;
					tf.setTextFormat(f, 0, 1);
				}
			}
			// восстановить фильтры
			tf.filters = fl;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Карта текстов ярлыков */
		protected var m_texts:Dictionary;
		
		/** Карта флагов автоматического выравнивания */
		protected var m_textsAuto:Dictionary;
		
		private static const SIZE_MIN:int = 8; // минимальный размер шрифта поля при автовыравнивании
		
	}

}
