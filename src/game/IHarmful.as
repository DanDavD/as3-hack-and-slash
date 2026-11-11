package game
{
	import flash.geom.Rectangle;

	// anything that hurts the hero on touch. enemies and bullets
	// interface bc a bullet isnt an Entity, they share nothing else
	public interface IHarmful
	{
		// no public in here, the compiler yells
		function get hitBox():Rectangle;
		function get canHurt():Boolean;
		function get contactDamage():int;
	}
}
