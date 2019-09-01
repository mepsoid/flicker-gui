package ui.common {
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;
	import flash.utils.Dictionary;
	
	/**
	 * Универсальный контейнер клипов
	 * 
	 * @version  1.0.19
	 * @author   meps
	 */
	public class CGContainer extends CGDispatcher implements IGSkinnable {
		
		public function CGContainer(src:* = null, name:String = null) {
			m_const = new Dictionary();
			m_icons = new Dictionary();
			m_texts = new Dictionary();
			m_textsAuto = new Dictionary();
			m_placers = new Dictionary();
			super();
			if (src)
				clipAppend(src, name);
		}
		
		/** Деструктор */
		public function destroy():void {
			//log.write("#", "CGProto::destroy");
			onDestroy();
			m_clipInstance = null;
			m_parent = null;
			m_const = null;
			m_icons = null;
			m_texts = null;
			m_textsAuto = null;
			// удалить все плейсхолдеры
			for each (var placer:TPlacerData in m_placers)
				placer.target.destroy();
			m_placers = null;
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
		 * clipAppend("class") -- использовать графику из класса с заданным именем
		 *
		 * Использование:
		 * var e1:CGElement = new CGElement(this, "el_name");
		 * либо:
		 * var e2:CGElement = new CGElement();
		 * e2.clipAppend(this, "el_name");
		 */
		public function clipAppend(src:*, name:String = null):void {
			var mc:MovieClip;
			if (m_clipInstance || m_parent)
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
				// имя ресурса (пока совпадает с именем класса)
				m_srcResource = String(src);
				CGSkin.instance.connect(m_srcResource, this);
				return;
				/*
				// имя класса
				try {
					var cl:Class = getDefinitionByName(src as String) as Class;
				} catch (error:Error) {
					return;
				}
				if (!cl)
					// отсутствующий класс не может быть использован
					return;
				mc = new cl() as MovieClip;
				if (!mc)
					// пустой клип из класса не может быть использован
					return;
				*/
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
		
		/** Чтение состояния иконки */
		public function iconGet(id:String):String {
			if (!(id in m_icons))
				return null;
			return m_icons[id];
		}
		
		/** Установка состояния иконки */
		public function iconSet(state:String, id:String):void {
			if (id in m_icons)
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
		
		/** Зарегистрировать плейсхолдер */
		public function placerAttach(placerId:String, target:IGAligner, applyMatrix:Boolean = false, clipRect:Boolean = false, clipMask:Boolean = false):void {
			var desc:TPlacerData;
			if (placerId in m_placers) {
				// удалить старый обработчик
				desc = m_placers[placerId];
				desc.target.destroy();
				desc.placer = null;
				desc.view = null;
				desc.applyMatrix = applyMatrix;
				desc.clipRect= clipRect;
				desc.clipMask = clipMask;
			} else {
				desc = new TPlacerData(applyMatrix, clipRect, clipMask);
				m_placers[placerId] = desc;
			}
			desc.target = target;
			placerRedraw(placerId);
		}
		
		/** Удалить плейсхолдер */
		public function placerDetach(placerId:String):void {
			if (!(placerId in m_placers))
				return;
			var desc:TPlacerData = m_placers[placerId];
			desc.target.destroy();
			delete m_placers[placerId];
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
				return src ? src : m_clipInstance;
			var container:DisplayObjectContainer;
			if (src)
				// передан конкретный контейнер
				container = src;
			else if (m_clipInstance)
				// искать по собственному клипу элемента
				container = m_clipInstance;
			else
				// поиск заведомо невозможен
				return null;
			// собрать путь для поиска
			var direct:Vector.<Boolean> = new Vector.<Boolean>(); // флаг поиска непосредственно по имени; сброшен -- поиск иерархический
			var path:Vector.<String> = new Vector.<String>(); // имена объектов
			SPLIT_PATH.lastIndex = 0;
			var pathResult:Object = SPLIT_PATH.exec(name);
			while (pathResult) {
				var pathDirect:Boolean = String(pathResult[1]) == "."; // непосредственный поиск только если ведущая точка одна
				direct.push(pathDirect);
				var pathName:String = String(pathResult[2]);
				path.push(pathName);
				pathResult = SPLIT_PATH.exec(name);
			}
			// поиск запрошенного объекта
			var found:DisplayObject = null;
			var depth:int = 0; // текущая глубина обхода
			while (depth < path.length) {
				if (!container)
					// нарушена структура иерархии, например, промежуточное имя пути связано не с контейнером и дальнейшее углубление невозможно
					return null;
				pathDirect = direct[depth];
				pathName = path[depth];
				if (pathDirect) {
					// непосредственное имя объекта
					found = container.getChildByName(pathName);
				} else {
					// иерархический поиск
					var list:Vector.<DisplayObjectContainer> = new <DisplayObjectContainer>[ container ];
					while (list.length) {
						// обходить все вложенные контейнеры в поисках нужного элемента
						container = list.pop();
						found = container.getChildByName(pathName);
						if (found)
							// найден нужный элемент
							break;
						// элемента нет, поместить в список все вложенные контейнеры для дальнейшего обхода
						for (var index:int = 0, len:int = container.numChildren; index < len; ++index) {
							var child:DisplayObjectContainer = container.getChildAt(index) as DisplayObjectContainer;
							if (child)
								list.unshift(child);
						}
					}
				}
				if (!found)
					// дальнейший поиск невозможен
					return null;
				container = found as DisplayObjectContainer; // для дальнейшего обхода по пути
				++depth;
			}
			return found;
		}
		
		/** Обработчис смены ресурса скина */
		public function skinUpdate(resourceId:String, data:*):void {
			if (resourceId == m_srcResource) {
				var mc:MovieClip = data as MovieClip;
				doClipAppend(mc);
				doClipProcess();
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Стандартный обработчик каждого обновления текстового поля */
		protected function onTextUpdate(field:TextField, textId:String, textValue:String):void {
			doTextRefit(field, textValue, m_textsAuto[textId]);
		}
		
		/** Обработчик деструктора элемента */
		protected function onDestroy():void {
			//clipRemove();
			if (m_parent) {
				// отписать обработчики от всех событий удаляемого элемента
				m_parent.eventSign(false, UPDATE, doClipParent);
				m_parent = null
			}
			// удалить регистрацию обработчика смены скина
			if (m_srcResource) {
				CGSkin.instance.disconnect(m_srcResource, this);
				m_srcResource = null;
			}
			m_const = null;
			m_icons = null;
			m_texts = null;
			m_textsAuto = null;
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
			if (!mc) {
				doClipRemove();
				return;
			}
			if (mc === m_clipInstance)
				return;
			m_clipInstance = mc;
			onClipAppend(m_clipInstance);
		}
		
		/** Удалить регистрацию клипа */
		protected function doClipRemove():void {
			//trace(printClass(this), "::doClipRemove", printClass(m_clipInstance));
			if (m_clipInstance) {
				onClipRemove(m_clipInstance);
				m_clipInstance = null;
			}
		}
		
		/** Внутреннее обновление клипа в связи с изменением его состояния */
		protected function doClipProcess():void {
			var n:String, id:String;
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
			for (id in m_icons) {
				var mc:MovieClip = objectFind(id) as MovieClip;
				if (mc) {
					try {
						mc.gotoAndStop(m_icons[id]);
					} catch(error:Error) {
						mc.stop();
					}
				}
			}
			// обновить все тексты
			for (id in m_texts) {
				var tf:TextField = objectFind(id) as TextField;
				if (tf)
					onTextUpdate(tf, id, m_texts[id]);
			}
			// обновить все плейсхолдеры
			for (id in m_placers)
				placerRedraw(id);
			// прочие специфические действия над контейнером
			onClipProcess();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработчик события смены состояния связанного родительского элемента */
		private function doClipParent(event:CGEvent):void {
			onClipParent();
			doClipProcess();
		}
		
		/** Обработчик события изменения текста в поле ввода */
		private function onTextChange(event:Event):void {
			//log.write("onTextUpdate", (e.target as TextField).name, (e.target as TextField).text);
			var tf:TextField = event.target as TextField;
			var name:String = tf.name;
			if (name) {
				m_texts[name] = tf.text;
				eventSend(new CGEventChange(CGEventChange.TEXT, name));
			}
		}
		
		/** Выравнивание текстового поля */
		private function doTextRefit(tf:TextField, tx:String, auto:Boolean):void {
			var fmt:TextFormat = tf.getTextFormat();
			tf.mouseEnabled = false;// !auto; // запретить взаимодействие с автоматически выравнивающимися текстовыми полями
			tf.defaultTextFormat = fmt;
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
			var fs:Number = fmt.size as Number;
			fmt.blockIndent = 0;
			if (tw > w || th > h) {
				// если реальная ширина или высота больше, уменьшать шрифт, до полного влезания текста в область
				while (fs > 1 && (tw > w || th > h)) {
					--fs;
					fmt.size = fs;
					tf.defaultTextFormat = fmt;
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
					fmt.size = fs;
					tf.defaultTextFormat = fmt;
					tf.text = tf.text;
					tw = tf.textWidth;
					th = tf.textHeight;
				}
			}
			if (th < h) {
				// вертикальное выравнивание; создать вертикальный отступ за счет перевода в начале строки
				var mtr:TextLineMetrics = tf.getLineMetrics(0);
				var t:Number = Number(fmt.size) * (h - th) * 0.5 / mtr.height;
				if (t > 1) {
					fmt.size = t;
					tf.text = "\n" + tf.text;
					tf.setTextFormat(fmt, 0, 1);
				}
			}
			// восстановить фильтры
			tf.filters = fl;
		}
		
		/** Перерисовать плейсер */
		private function placerRedraw(id:String):void {
			var parent:DisplayObjectContainer;
			var descr:TPlacerData = m_placers[id];
			var placer:DisplayObject = objectFind(id);
			var view:DisplayObject = descr.target.view;
			// обработать отображение
			if (placer) {
				// есть плейсер
				placer.visible = false;
				if (view !== descr.view || placer !== descr.placer) {
					// прежняя графика
					if (descr.view) {
						// есть старая графика, но она поменялась -- удалить
						parent = descr.view.parent;
						if (parent)
							parent.removeChild(descr.view);
					}
					descr.view = null;
					// новая графика
					parent = placer.parent;
					if (view && parent) {
						// появилась новая графика, не равная старой -- отобразить
						var depth:int = parent.getChildIndex(placer);
						parent.addChildAt(view, depth);
						// сохранять указатель на старую графику только при ее фактическом добавлении
						descr.view = view;
					}
				}
				// выровнять графику по плейсеру
				if (view) {
					var placerRect:Rectangle, viewRect:Rectangle;
					parent = placer.parent;
					if (parent) {
						placerRect = placer.getBounds(parent);
						if (descr.applyMatrix) {
							// применить текущую матрицу
							var matr:Matrix = placer.transform.matrix;
							view.transform.matrix = matr;
							// спозиционировать ноль
							view.x = placerRect.x;
							view.y = placerRect.y;
							// TODO пересчитать отсечение по матрице (ПРИБЛИЖЕННО!)
							placerRect.width /= matr.a;
							placerRect.height /= matr.d;
						} else {
							// спозиционировать ноль
							view.x = placerRect.x;
							view.y = placerRect.y;
						}
						// отсечь по прямоугольной области и обновить графику
						placerRect.x = 0;
						placerRect.y = 0;
						if (descr.clipRect)
							view.scrollRect = placerRect;
						if (descr.clipMask)
							view.mask = placer;
						descr.target.resize(placerRect);
					}
				}
			} else {
				// плейсер не найден или был удален; убрать графику со сцены
				if (descr.view) {
					parent = descr.view.parent;
					if (parent)
						parent.removeChild(descr.view);
				}
				descr.view = null;
			}
			descr.placer = placer;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Используемый в элементе клип, если он существует */
		private var m_clipInstance:MovieClip;
		
		/** Используемый идентификатор ресурса скина */
		private var m_srcResource:String;
		
		/** Имя клипа */
		protected var m_clipName:String;
		
		/** Родительский элемент, который отслеживается */
		protected var m_parent:CGContainer;
		
		/** Хранилище констант элемента */
		private var m_const:Dictionary/*String*/;
		
		/** Карта текущих состояний иконок */
		protected var m_icons:Dictionary/*String*/;
		
		/** Карта текстов ярлыков */
		protected var m_texts:Dictionary;
		
		/** Карта флагов автоматического выравнивания */
		protected var m_textsAuto:Dictionary;
		
		/** Карта зарегистрированных плейсеров */
		protected var m_placers:Dictionary;
		
		protected static const UPDATE:String = "$parent_update$";
		
		private static const CLEAN_CONST:RegExp = /[^\w\.]/g; // шаблон для очистки констант от служебных символов
		private static const SPLIT_PATH:RegExp = /(^|\.+)([-\w]+)/g; // шаблон для разделения пути на элементы
		private static const NAME_SPLITER:String = "$";
		private static const SIZE_MIN:int = 8; // минимальный размер шрифта поля при автовыравнивании
		
	}
	
}

import flash.display.DisplayObject;
import ui.common.IGAligner;

internal class TPlacerData {
	
	public var target:IGAligner; // контроллер графики плейсхолдера
	public var placer:DisplayObject; // текущий экземпляр плейсхолдера
	public var view:DisplayObject; // текущий экземпляр графики
	public var applyMatrix:Boolean;
	public var clipRect:Boolean;
	public var clipMask:Boolean;
	
	public function TPlacerData(matrix:Boolean, rect:Boolean, mask:Boolean) {
		applyMatrix = matrix;
		clipRect = rect;
		clipMask = mask;
	}
	
}
