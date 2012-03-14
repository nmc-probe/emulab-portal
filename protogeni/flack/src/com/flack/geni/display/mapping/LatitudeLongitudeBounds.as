package com.flack.geni.display.mapping
{
	public class LatitudeLongitudeBounds
	{
		public var north:Number;	// highest latitude
		public var south:Number;	// lowest latitude
		public var east:Number;		// right longitude
		public var west:Number;		// left longitude
		
		public function get Center():LatitudeLongitude
		{
			if(!isNaN(north) && !isNaN(south) && !isNaN(east) && !isNaN(west))
			{
				return new LatitudeLongitude((north+south)/2, (east+west)/2);
			}
			else
				return null;
		}
		
		public function get SouthWest():LatitudeLongitude
		{
			if(isNaN(south) && isNaN(west))
				return new LatitudeLongitude(south, west);
			else
				return null;
		}
		
		public function get NorthEast():LatitudeLongitude
		{
			if(isNaN(north) && isNaN(east))
				return new LatitudeLongitude(north, east);
			else
				return null;
		}
		
		public function LatitudeLongitudeBounds(swCorner:LatitudeLongitude = null, neCorner:LatitudeLongitude = null)
		{
			if(neCorner != null && swCorner != null)
			{
				north = neCorner.latitude;
				south = swCorner.latitude;
				east = neCorner.longitude;
				west = swCorner.longitude;
			}
			else
			{
				north = NaN;
				south = NaN;
				east = NaN;
				west = NaN;
			}
		}
	}
}