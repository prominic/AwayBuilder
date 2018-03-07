package awaybuilder.desktop.controller
{
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.ResizeEvent;
	
	import awaybuilder.controller.events.SceneReadyEvent;
	
	import org.robotlegs.mvcs.Command;

	public class SceneReadyCommand extends Command
	{
		[Inject]
		public var event:SceneReadyEvent;
		
		private var _app:AwayBuilderApplication;
		
		private var _alpha:Number = 1;
		
		override public function execute():void
		{
			// for in-Moonshine use
			if (CONFIG::MOONSHINE)
			{
				var tmpSplashScreen:SplashScreenLib = SplashScreenLib.getInstance();
				tmpSplashScreen.close();
				return;
			}
			
			_app = FlexGlobals.topLevelApplication as AwayBuilderApplication;
			_app.addEventListener(Event.ENTER_FRAME, enterFrameHandler );
			_app.alwaysInFront = true;
			_app.alwaysInFront = false;
			_app.splashScreen.alwaysInFront = true;
		}
		private function enterFrameHandler( event:Event ):void
		{
			if( _alpha <=0 )
			{
				_app.removeEventListener(Event.ENTER_FRAME, enterFrameHandler );
				_app.splashScreen.close();
				return;
			}
			_alpha -= 0.095;
			
			_app.splashScreen.setAlpha(_alpha);
		}
		
	}
}