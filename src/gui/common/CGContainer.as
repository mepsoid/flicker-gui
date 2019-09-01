package framework.gui {
	
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
	 * @version  1.0.25
	 * @author   meps
	 */
	public class CGContainer extends CGDispatcher implements IGSkinnable {
		
		public function CGContainer(src:* = null, name:String = null) {
			mConst = new Dictionary();
			mIcons = new Dictionary();
			mTexts = new Dictionary();
			mTextsAuto = new Dictionary();
			mPlacers = new Dictionary();
			super();
			if (src)
				clipAppend(src, name);
		}
		
		/** Деструктор */
		public function destroy():void {
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
			if (mClipInstance || mParent)
				// если клип уже существует, сначала удалить его
				clipRemove();
			if (src is MovieClip) {
				// явно передаваемый клип
				mc = src as MovieClip;
				if (name)
					mc = objectFind(name, mc) as MovieClip;
				if (!mc) {
					// пустой клип не может быть использован
					return;
				}
			} else if (src is CGContainer) {
				// клип существующего родительского элемента интерфейса
				var parent:CGContainer = src as CGContainer;
				mParent = parent;
				mParent.eventSign(true, UPDATE, doClipParent);
				mClipName = name;
				mc = mParent.objectFind(mClipName) as MovieClip; // связанный с существующим элементом клип может и отсутствовать
			} else if (src is Class) {
				mc = new (src as Class)() as MovieClip;
				if (!mc)
					return;
			} else if (src is String) {
				// имя ресурса (пока совпадает с именем класса)
				mSrcResource = String(src);
				CGSkin.instance.connect(mSrcResource, this);
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
				return;
			}
			doClipAppend(mc);
			doClipProcess();
		}
		
		/** Удалить клип */
		public function clipRemove():void {
			if (mParent) {
				mParent.eventSign(false, UPDATE, doClipParent);
				mParent = null;
				mClipName = null;
			}
			doClipRemove();
		}
		
		/** Прочитать значение константы из текстового поля */
		public function constGet(name:String, bobbles:Boolean = false):String {
			if (!mConst)
				return null;
			
			var result:String = mConst[name];
			if (!result || bobbles) {
				var t:TextField = objectFind(name) as TextField;
				if (t) {
					t.visible = false;
					result = t.text.replace(CLEAN_CONST, ""); // удалить все служебные символы
					mConst[name] = result;
				} else {
					// сохранить имя константы для отслеживания изменения ее значения
					result = null;
					// если константа не найдена то ищем ее у родителей
					if (bobbles && mParent && mClipName) {
						var findName:String = String(mClipName + NAME_SPLITER + name).replace(/[^\w\$]/g, "");
						result = mParent.constGet(findName, bobbles);
					}
					mConst[name] = result;
				}
			}
			return result;
		}
		
		/** Чтение текстового поля */
		public function textGet(id:String):String {
			if (!mTexts.hasOwnProperty(id))
				return null;
			return mTexts[id];
		}
		
		/** Запись текстового поля */
		public function textSet(text:String, id:String, auto:Boolean = false):void {
			mTextsAuto[id] = auto;
			if (mTexts.hasOwnProperty(id))
				if (mTexts[id] == text)
					// содержание текста не менялось
					return;
			mTexts[id] = text;
			// обновлять только затронутые изменением текстовые поля
			var tf:TextField = objectFind(id) as TextField;
			if (tf)
				onTextUpdate(tf, id, mTexts[id]);
			eventSend(new CGEventChange(CGEventChange.TEXT, id));
		}
		
		/** Чтение состояния иконки */
		public function iconGet(id:String):String {
			if (!(id in mIcons))
				return null;
			return mIcons[id];
		}
		
		/** Установка состояния иконки */
		public function iconSet(state:String, id:String):void {
			if (id in mIcons)
				if (mIcons[id] == state)
					// состояние иконки не менялось
					return;
			mIcons[id] = state;
			// обновлять только затронутые изменением клипы иконок
			var mc:MovieClip = objectFind(id) as MovieClip;
			if (mc)
				try {
					mc.gotoAndStop(mIcons[id]);
				} catch(error:Error) {
					mc.stop();
				}
			eventSend(new CGEventChange(CGEventChange.ICON, id));
		}
		
		/** Зарегистрировать плейсхолдер */
		public function placerAttach(placerId:String, target:IGAligner, applyMatrix:Boolean = false, clipRect:Boolean = false, clipMask:Boolean = false):void {
			var desc:TPlacerData;
			if (placerId in mPlacers) {
				// удалить старый обработчик
				desc = mPlacers[placerId];
				desc.target.destroy();
				desc.placer = null;
				desc.view = null;
				desc.applyMatrix = applyMatrix;
				desc.clipRect = clipRect;
				desc.clipMask = clipMask;
			} else {
				desc = new TPlacerData(applyMatrix, clipRect, clipMask);
				mPlacers[placerId] = desc;
			}
			desc.target = target;
			placerRedraw(placerId);
		}
		
		/** Удалить плейсхолдер */
		public function placerDetach(placerId:String):void {
			if (!(placerId in mPlacers))
				return;
			var desc:TPlacerData = mPlacers[placerId];
			desc.target.destroy();
			delete mPlacers[placerId];
		}
		
		/** Связанный с контроллером клип */
		public function get clip():MovieClip { return mClipInstance; }
		
		/** Посчитать количество занумерованных последовательно элементов по переданному префиксу */
		public function objectCount(name:String, src:DisplayObjectContainer = null):int {
			if (!src)
				src = mClipInstance;
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
				return src ? src : mClipInstance;
			var container:DisplayObjectContainer;
			if (src)
				// передан конкретный контейнер
				container = src;
			else if (mClipInstance)
				// искать по собственному клипу элемента
				container = mClipInstance;
			else
				// поиск заведомо невозможен
				return null;
			// собрать путь для поиска
			mHelperDirect.length = 0; // флаг поиска непосредственно по имени; сброшен -- поиск иерархический
			mHelperPath.length = 0; // имена объектов
			SPLIT_PATH.lastIndex = 0;
			var pathResult:Object = SPLIT_PATH.exec(name);
			while (pathResult) {
				var pathDirect:Boolean = String(pathResult[1]) == "."; // непосредственный поиск только если ведущая точка одна
				mHelperDirect.push(pathDirect);
				var pathName:String = String(pathResult[2]);
				mHelperPath.push(pathName);
				pathResult = SPLIT_PATH.exec(name);
			}
			// поиск запрошенного объекта
			var found:DisplayObject = null;
			var depth:int = 0; // текущая глубина обхода
			while (depth < mHelperPath.length) {
				if (!container)
					// нарушена структура иерархии, например, промежуточное имя пути связано не с контейнером и дальнейшее углубление невозможно
					return null;
				pathDirect = mHelperDirect[depth];
				pathName = mHelperPath[depth];
				if (pathDirect) {
					// непосредственное имя объекта
					found = container.getChildByName(pathName);
				} else {
					// иерархический поиск
					mHelperList.length = 0;
					mHelperList[0] = container;
					while (mHelperList.length) {
						// обходить все вложенные контейнеры в поисках нужного элемента
						container = mHelperList.pop();
						found = container.getChildByName(pathName);
						if (found)
							// найден нужный элемент
							break;
						// элемента нет, поместить в список все вложенные контейнеры для дальнейшего обхода
						for (var index:int = 0, len:int = container.numChildren; index < len; ++index) {
							var child:DisplayObjectContainer = container.getChildAt(index) as DisplayObjectContainer;
							if (child)
								mHelperList.unshift(child);
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
			if (resourceId == mSrcResource) {
				var mc:MovieClip = data as MovieClip;
				doClipAppend(mc);
				doClipProcess();
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Стандартный обработчик каждого обновления текстового поля */
		protected function onTextUpdate(field:TextField, textId:String, textValue:String):void {
			doTextRefit(field, textValue, mTextsAuto[textId]);
		}
		
		/** Обработчик деструктора элемента */
		protected function onDestroy():void {
			//clipRemove();
			eventClear();
			// удалить все плейсхолдеры
			for each (var placer:TPlacerData in mPlacers)
				placer.target.destroy();
			mPlacers = null;
			// отписать обработчики от всех событий удаляемого элемента
			if (mParent) {
				mParent.eventSign(false, UPDATE, doClipParent);
				mParent = null
			}
			// удалить регистрацию обработчика смены скина
			if (mSrcResource) {
				CGSkin.instance.disconnect(mSrcResource, this);
				mSrcResource = null;
			}
			mClipInstance = null;
			mConst = null;
			mIcons = null;
			mTexts = null;
			mTextsAuto = null;
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
			mConst[name] = value;
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
			if (!mc) {
				doClipRemove();
				return;
			}
			if (mc === mClipInstance)
				return;
			mClipInstance = mc;
			onClipAppend(mClipInstance);
		}
		
		/** Удалить регистрацию клипа */
		protected function doClipRemove():void {
			if (mClipInstance) {
				onClipRemove(mClipInstance);
				mClipInstance = null;
			}
		}
		
		/** Внутреннее обновление клипа в связи с изменением его состояния */
		protected function doClipProcess():void {
			var n:String, id:String;
			if (mClipInstance == null) {
				for (n in mConst)
					mConst[n] = null;
				return;
			}
			// обновить значения констант
			for (n in mConst) {
				var t:TextField = objectFind(n) as TextField;
				if (t) {
					t.visible = false;
					mConst[n] = t.text.replace(CLEAN_CONST, ""); // удалить все служебные символы
				} else {
					// отсутствие на клипе текстовых полей стирает прежние значения констант
					//m_const[n] = null;
				}
			}
			// обновить все иконки
			for (id in mIcons) {
				var mc:MovieClip = objectFind(id) as MovieClip;
				if (mc) {
					try {
						mc.gotoAndStop(mIcons[id]);
					} catch(error:Error) {
						mc.stop();
					}
				}
			}
			// обновить все тексты
			for (id in mTexts) {
				var tf:TextField = objectFind(id) as TextField;
				if (tf)
					onTextUpdate(tf, id, mTexts[id]);
			}
			// обновить все плейсхолдеры
			for (id in mPlacers)
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
			var tf:TextField = event.target as TextField;
			var name:String = tf.name;
			if (name) {
				mTexts[name] = tf.text;
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
			tf.removeEventListener(Event.CHANGE, onTextChange);
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
			var descr:TPlacerData = mPlacers[id];
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
		private var mClipInstance:MovieClip;
		
		/** Используемый идентификатор ресурса скина */
		private var mSrcResource:String;
		
		// хелперы при построении пути к объекту
		private var mHelperDirect:Vector.<Boolean> = new Vector.<Boolean>();
		private var mHelperPath:Vector.<String> = new Vector.<String>();
		private var mHelperList:Vector.<DisplayObjectContainer> = new Vector.<DisplayObjectContainer>();
		
		/** Имя клипа */
		protected var mClipName:String;
		
		/** Родительский элемент, который отслеживается */
		protected var mParent:CGContainer;
		
		/** Хранилище констант элемента */
		private var mConst:Dictionary/*String*/;
		
		/** Карта текущих состояний иконок */
		protected var mIcons:Dictionary/*String*/;
		
		/** Карта текстов ярлыков */
		protected var mTexts:Dictionary;
		
		/** Карта флагов автоматического выравнивания */
		protected var mTextsAuto:Dictionary;
		
		/** Карта зарегистрированных плейсеров */
		protected var mPlacers:Dictionary;
		
		protected static const UPDATE:String = "$parent_update$";
		
		private static const CLEAN_CONST:RegExp = /[^\w\.]/g; // шаблон для очистки констант от служебных символов
		private static const SPLIT_PATH:RegExp = /(^|\.+)([-$_\w]+)/g; // шаблон для разделения пути на элементы
		private static const NAME_SPLITER:String = "$";
		private static const SIZE_MIN:int = 8; // минимальный размер шрифта поля при автовыравнивании
		
	}
	
}

import flash.display.DisplayObject;
import framework.gui.IGAligner;

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
