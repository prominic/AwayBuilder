package awaybuilder.controller.document
{
	import awaybuilder.controller.document.events.ImportTextureEvent;
	import awaybuilder.controller.events.ReplaceDocumentDataEvent;
	import awaybuilder.model.IDocumentService;
	
	import org.robotlegs.mvcs.Command;

	public class ImportBitmapCommand extends Command
	{
		[Inject]
		public var event:ImportTextureEvent;
		
		[Inject]
		public var fileService:IDocumentService;
		
		override public function execute():void
		{
			if (event.type == ImportTextureEvent.IMPORT_AND_BITMAP_REPLACE) this.fileService.openBitmap( event.items , event.options as String  );
			else if (event.type == ImportTextureEvent.IMPORT_AND_BITMAP_REPLACE_FROM_MOONSHINE) 
			{
				var nextEvent:ReplaceDocumentDataEvent = new ReplaceDocumentDataEvent(ReplaceDocumentDataEvent.REPLACE_DOCUMENT_DATA );
				this.fileService.openByMoonshine( event.items, nextEvent );
			}
		}
	}
}