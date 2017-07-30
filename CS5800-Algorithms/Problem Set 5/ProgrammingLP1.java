import ilog.concert.*;
import ilog.cplex.*;
public class ProgrammingLP1 {

	public static void main(String[] args) 
	{
		try 
		{
			IloCplex cplex = new IloCplex();
			double[] lb = {0.0, 0.0, 0.0};
			double[] ub = {Double.MAX_VALUE, Double.MAX_VALUE, Double.MAX_VALUE};
			IloNumVar[] x = cplex.numVarArray(3, lb, ub);
			double[] objvals = {55.0, 100.0, 125.0};
			
			cplex.addMaximize(cplex.scalProd(x, objvals));
			
			// 18 * A + 36 * B + 24 * C <= 2100
			cplex.addLe(cplex.sum(cplex.prod(18.0, x[0]),
									cplex.prod( 36.0, x[1]),
									cplex.prod( 24.0, x[2])), 2100.0);
			
			//2 * 8 * A + 6 * 8 * B + 4 * 8 *C <= 2400
			cplex.addLe(cplex.sum(cplex.prod( 16.0, x[0]),
									cplex.prod( 48.0, x[1]),	
									cplex.prod( 32.0, x[2])), 2400.0);
			
			// x1 i.e. A + x2 i.e. B + x3 i.e. C <= 100
			cplex.addLe(cplex.sum( x[0],
								   x[1],
								   x[2]), 100.0);
			
			if ( cplex.solve() ) 
			{
				System.out.println("Maximum revenue = " + cplex.getObjValue());
				double[] val = cplex.getValues(x);
				int ncols = cplex.getNcols();
				for (int j = 0; j < ncols; ++j)
				{
					System.out.println("No of Type " + (char) (65 + j) + " Widgets: " + val[j]);
				}
			}
			cplex.end();
		}
		catch (IloException e)
		{
			System.err.println("Concert exception '" + e + "' caught");
		}
	}
}