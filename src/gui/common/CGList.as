package ui.common {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	/**
	 * Список произвольных элементов с прокруткой
	 * 
	 * @version  1.0.2
	 * @author   meps
	 */
	public class CGList extends CGLabel {
		
		public function CGList(src:* = null, name:String = null) {
			super(src, name);
			m_scroll = new CGScroll(this, SCROLL_ID);
			m_butPrevItem = new CGButton(this, PREVITEM_ID);
			m_butPrevItem.eventSign(true, CGEvent.CLICK, onPrevItem);
			m_butNextItem = new CGButton(this, NEXTITEM_ID);
			m_butNextItem.eventSign(true, CGEvent.CLICK, onNextItem);
			m_butPrevPage = new CGButton(this, PREVPAGE_ID);
			m_butPrevPage.eventSign(true, CGEvent.CLICK, onPrevPage);
			m_butNextPage = new CGButton(this, NEXTPAGE_ID);
			m_butNextPage.eventSign(true, CGEvent.CLICK, onNextPage);
			m_butFirstItem = new CGButton(this, FIRSTITEM_ID);
			m_butFirstItem.eventSign(true, CGEvent.CLICK, onFirstItem);
			m_butLastItem = new CGButton(this, LASTITEM_ID);
			m_butLastItem.eventSign(true, CGEvent.CLICK, onLastItem);
			constDefault(STEP_CONST, "1");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onClipAppend(mc:MovieClip):void {
			super.onClipAppend(mc);
			// подписаться на колесо по всей рабочей области
			var hitMc:MovieClip = objectFind(HIT_ID) as MovieClip;
			if (!hitMc)
				hitMc = mc;
			hitMc.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
		
		override protected function onClipRemove(mc:MovieClip):void {
			// снять подписку на колесо с области
			var hitMc:MovieClip = objectFind(HIT_ID) as MovieClip;
			if (!hitMc)
				hitMc = mc;
			hitMc.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			super.onClipRemove(mc);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Обработчик колеса мыши */
		private function onMouseWheel(event:MouseEvent):void {
		}
		
		/** Обработчик кнопки перехода на шаг назад */
		private function onPrevItem(event:CGEvent):void {
		}
		
		/** Обработчик кнопки перехода на шаг вперед */
		private function onNextItem(event:CGEvent):void {
		}
		
		/** Обработчик кнопки перехода на предыдующую страницу */
		private function onPrevPage(event:CGEvent):void {
		}
		
		/** Обработчик кнопки перехода на следующую страницу */
		private function onNextPage(event:CGEvent):void {
		}
		
		/** Обработчик кнопки перехода в начало списка */
		private function onFirstItem(event:CGEvent):void {
		}
		
		/** Обработчик кнопки перехода в конец списка */
		private function onLastItem(event:CGEvent):void {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Список отображаемых данных */
		private var m_listData:Vector.<Object>;
		
		private var m_scroll:CGScroll;
		private var m_butPrevItem:CGButton; // кнопки управления
		private var m_butNextItem:CGButton;
		private var m_butPrevPage:CGButton;
		private var m_butNextPage:CGButton;
		private var m_butFirstItem:CGButton;
		private var m_butLastItem:CGButton;
		
		private static const STEP_CONST:String = ".step"; // константа шага для прокрутки длинных сгруппированных списков
		private static const SCROLL_ID:String = ".scroll"; // идентификатор скроллбара
		private static const PREVITEM_ID:String = ".btn_previtem"; // идентификаторы кнопок управления позиционированием
		private static const NEXTITEM_ID:String = ".btn_nextitem";
		private static const PREVPAGE_ID:String = ".btn_prevpage";
		private static const NEXTPAGE_ID:String = ".btn_nextpage";
		private static const FIRSTITEM_ID:String = ".btn_firstitem";
		private static const LASTITEM_ID:String = ".btn_lastitem";
		
	}

}