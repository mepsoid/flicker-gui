package ui.common {
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	
	/**
	 * Универсальный контейнер клипов
	 * 
	 * @version  1.0.8
	 * @author   meps
	 */
	public class CGContainer extends CGDispatcher {
		
		public function CGContainer(src:* = null, name:String = null) {
			m_const = new Dictionary();
			m_icons = new Dictionary();
			super();
			if (src)
				clipAppend(src, name);
		}
		
		/** Деструктор */
		public function destroy():void {
			//log.write("#", "CGProto::destroy");
			onDestroy();
		}
		
		/**
		 * Добавить клип
		 *
		 * @param  src- клип, которым будет управлять элемент или родительский
		 *          элемент, с клипами которого будет осуществляться работа;
		 *
		 * @param  name - если данный параметр указан, то первый параметр используется
		 *          как корневой клип для иерархического поиска потомка с данным
		 *          именем;
		 *
		 * clipAppend(MovieClip) -- использовать конкретный клип, необязательно отображаемый
		 * clipAppend(MovieClip, clipname) -- в переданном клипе найти по имени и использовать его
		 * clipAppend(CGProto) -- использовать все клипы родительского элемента
		 * clipAppend(CGProto, clipname) -- в родительском элементе среди клипов найти клип по имени и использовать его
		 *
		 * Использование:
		 * var e1:CGElement = new CGElement(this, "el_name");
		 * либо:
		 * var e2:CGElement = new CGElement();
		 * e2.clipAppend(this, "el_name");
		 */
		public function clipAppend(src:*, name:String = null):void {
			var mc:MovieClip;
			if (m_clipInstance != null || m_parent != null)
				// если клип уже существует, сначала удалить его
				clipRemove();
			if (src is MovieClip) {
				// явно передаваемый клип
				mc = src as MovieClip;
				if (name)
					mc = objectFind(name, mc) as MovieClip;
				if (!mc) {
					// пустой клип не может быть использован
					//log.write("!", "CGProto::clipAppend", "Empty clip", src, name);
					return;
				}
			} else if (src is CGContainer) {
				// клип существующего родительского элемента интерфейса
				var parent:CGContainer = src as CGContainer;
				m_parent = parent;
				//trace(printClass(this), "::clipAppend", "subscribe", printClass(m_parent));
				m_parent.eventSign(true, UPDATE, doClipParent);
				m_clipName = name;
				mc = m_parent.objectFind(m_clipName) as MovieClip; // связанный с существующим элементом клип может и отсутствовать
			} else if (src is Class) {
				mc = new (src as Class)() as MovieClip;
				if (!mc)
					return;
			} else if (src is String) {
				// имя класса
				try {
					var cl:Class = getDefinitionByName(src as String) as Class;
				} catch (error:Error) {
					//log.write("!", "CGProto::clipAppend", "No class definition for", src);
					return;
				}
				if (!cl)
					// отсутствующий класс не может быть использован
					return;
				mc = new cl() as MovieClip;
				if (!mc) {
					// пустой клип из класса не может быть использован
					//log.write("!", "CGProto::clipAppend", "Not movieclip class", src);
					return;
				}
			} else {
				// неведомый тип аргумента
				//log.write("!", "CGProto::clipAppend", "Unknown argument type", src, name);
				return;
			}
			doClipAppend(mc);
			doClipProcess();
			// FIX было в старой версии прототипа
			//doClipAppend(mc);
			//doClipState(m_state);
			//doClipProcess();
			//cast(new CGEvent(PARENT));
		}
		
		/** Удалить клип */
		public function clipRemove():void {
			if (m_parent) {
				m_parent.eventSign(false, UPDATE, doClipParent);
				m_parent = null;
				m_clipName = null;
			}
			doClipRemove();
			//cast(new CGEvent(PARENT));
		}
		
		/** Прочитать значение константы из текстового поля */
		public function constGet(name:String, bobbles:Boolean = false):String {
			var result:String = m_const[name];
			if (!result) {
				var t:TextField = objectFind(name) as TextField;
				if (t) {
					t.visible = false;
					result = t.text.replace(CLEAN_CONST, ""); // удалить все служебные символы
					m_const[name] = result;
				} else {
					// сохранить имя константы для отслеживания изменения ее значения
					result = null;
					m_const[name] = result;
				}
				// если константа не найдена то ищем ее у родителей
				if (bobbles && m_parent && m_clipName) {
					var findName:String = String(m_clipName + NAME_SPLITER + name).replace(/[^\w\$]/g, "");
					result = m_parent.constGet(findName, bobbles);
				}
			}
			return result;
		}
		
		/** Связанный с контроллером клип */
		public function get clip():MovieClip { return m_clipInstance; }
		
		/** Посчитать количество занумерованных последовательно элементов по переданному префиксу */
		public function objectCount(name:String, src:DisplayObjectContainer = null):int {
			if (!src)
				src = m_clipInstance;
			if (!src)
				return 0;
			var count:int = 0;
			while (objectFind(name + count.toString(), src))
				++count;
			return count;
		}
		
		// name = null -- использовать полный клип родителя
		// name = "<name>" -- провести полный иерархический поиск до первого совпадения
		// name = ".[<path>]<name>" -- взять конкретный клип
		// src = MovieClip -- явно переданный клип; используется при добавлении нового клипа
		// src = null -- искать в собственном клипе
		public function objectFind(name:String, src:DisplayObjectContainer = null):DisplayObject {
			if (!name)
				return m_clipInstance;
			var a:Array/*DisplayObject*/; // очередь обрабатываемых потомков
			var d:DisplayObject, c:DisplayObjectContainer;
			var n:int, m:int;
			var i:int, j:int;
			if (src)
				// передан клип
				a = [ src ];
			else if (m_clipInstance != null)
				// искать по собственному клипу элемента
				a = [ m_clipInstance ];
			else
				return null;
			// проверить имя
			i = name.indexOf(".");
			if (i == 0) {
				// в имени полный путь, найти соответствующий клип
				n = name.length;
				m = a.length;
				while (a.length) {
					c = a[--m];
					a.length = m;
					i = 0;
					while (i < n && c) {
						++i;
						j = name.indexOf(".", i);
						if (j < 0)
							j = n;
						var s:String = name.substring(i, j);
						d = c.getChildByName(s);
						c = d as DisplayObjectContainer;
						i = j;
					}
					if (d && i >= n)
						return d;
				}
				return null;
			}
			// в имени идентификатор клипа, провести полный иерархический поиск до первого совпадения
			while (a.length) {
				n = a.length - 1;
				d = a[n] as DisplayObject;
				a.length = n;
				if (!d)
					continue;
				if (d.name == name)
					return d;
				c = d as DisplayObjectContainer;
				if (c) {
					// у контейнеров собрать в очередь всех потомков
					m = c.numChildren;
					for (i = 0; i < m; ++i) {
						try {
							var o:DisplayObject = c.getChildAt(i);
						} catch (r:Error) {
							// FIXME читать файл политики?
							//log.write("!", "CGProto::objectFind", "Error at", c.name + ".getChildAt(" + i + ")");
							continue;
						}
						a[n] = o;
						++n;
					}
				}
			}
			return null;
		}
		
		/** Чтение состояния иконки */
		public function iconGet(id:String):String {
			if (!m_icons.hasOwnProperty(id))
				return null;
			return m_icons[id];
		}
		
		/** Установка состояния иконки */
		public function iconSet(state:String, id:String):void {
			if (m_icons.hasOwnProperty(id))
				if (m_icons[id] == state)
					// состояние иконки не менялось
					return;
			m_icons[id] = state;
			// обновлять только затронутые изменением клипы иконок
			var mc:MovieClip = objectFind(id) as MovieClip;
			if (mc)
				try {
					mc.gotoAndStop(m_icons[id]);
				} catch(error:Error) {
					mc.stop();
				}
			eventSend(new CGEventChange(CGEventChange.ICON, id));
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработчик дестркутора элемента */
		protected function onDestroy():void {
			clipRemove();
			if (m_parent) {
				// отписать обработчики от всех событий удаляемого элемента
				m_parent.eventSign(false, UPDATE, doClipParent);
				m_parent = null
			}
			m_const = null;
			m_icons = null;
			eventClear();
		}
		
		/** Обработчик добавления клипа */
		protected function onClipAppend(mc:MovieClip):void {
		}
		
		/** Обработчик удаления клипа */
		protected function onClipRemove(mc:MovieClip):void {
		}
		
		/** Установить значения констант по умолчанию и тем самым инициировать
		    дальнейшие запросы значений констант из текстовых полей */
		protected function constDefault(name:String, value:String = null):void {
			m_const[name] = value;
		}
		
		/** Внутреннее обновление клипа в связи с изменением его состояния */
		protected function onClipProcess():void {
		}
		
		/** Обработчик смены состояния связанного родительского элемента */
		protected function onClipParent():void {
		}

		////////////////////////////////////////////////////////////////////////
		
		/** Зарегистрировать новый клип */
		protected function doClipAppend(mc:MovieClip):void {
			//trace(printClass(this), "::doClipAppend", printClass(mc), "-->", printClass(m_clipInstance));
			if (!mc || mc === m_clipInstance)
				return;
			m_clipInstance = mc;
			onClipAppend(m_clipInstance);
		}
		
		/** Удалить регистрацию клипа */
		protected function doClipRemove():void {
			//trace(printClass(this), "::doClipRemove", printClass(m_clipInstance));
			if (m_clipInstance != null) {
				onClipRemove(m_clipInstance);
				m_clipInstance = null;
			}
		}
		
		/** Обработчик события смены состояния связанного родительского элемента */
		private function doClipParent(event:CGEvent):void {
			onClipParent();
			doClipProcess();
		}
		
		/** Внутреннее обновление клипа в связи с изменением его состояния */
		protected function doClipProcess():void {
			var n:String;
			if (m_clipInstance == null) {
				for (n in m_const)
					m_const[n] = null;
				return;
			}
			// обновить значения констант
			for (n in m_const) {
				var t:TextField = objectFind(n) as TextField;
				if (t) {
					t.visible = false;
					m_const[n] = t.text.replace(CLEAN_CONST, ""); // удалить все служебные символы
				} else {
					// отсутствие на клипе текстовых полей стирает прежние значения констант
					//m_const[n] = null;
				}
			}
			// обновить все иконки
			for (var id:String in m_icons) {
				var mc:MovieClip = objectFind(id) as MovieClip;
				if (mc) {
					try {
						mc.gotoAndStop(m_icons[id]);
					} catch(error:Error) {
						mc.stop();
					}
				}
			}
			onClipProcess();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Используемый в элементе клип, если он существует */
		private var m_clipInstance:MovieClip;
		
		/** Имя клипа */
		protected var m_clipName:String;
		
		/** Родительский элемент, который отслеживается */
		protected var m_parent:CGContainer;
		
		/** Хранилище констант элемента */
		private var m_const:Dictionary/*String*/;
		
		/** Карта текущих состояний иконок */
		protected var m_icons:Dictionary/*String*/;
		
		protected static const UPDATE:String = "$parent_update$";
		
		private static const CLEAN_CONST:RegExp = /[^\w\.]/g; // шаблон для очистки констант от служебных символов
		private static const NAME_SPLITER:String = "$";
		
	}

}