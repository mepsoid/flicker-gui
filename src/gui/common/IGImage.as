package framework.gui {
	
	/**
	 * Интерфейс асинхронно обновляемых подгружаемых изображений
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public interface IGImage {
		
		/** Обработчик результатов загрузки изображения */
		function imageUpdate(result:CGImageResult):void;
		
	}
	
}
