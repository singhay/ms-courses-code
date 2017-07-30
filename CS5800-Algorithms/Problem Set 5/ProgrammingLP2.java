import ilog.concert.*;
import ilog.cplex.*;
public class ProgrammingLP2 {

	public static void main(String[] args) 
	{
		try 
		{
			// 0 = AB, 1 = AC, 2 = AD, 3 = BC, 4 = BD, 5 = DC
			IloCplex cplex = new IloCplex();
			double[] lb = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
			double[] ub = {Long.MAX_VALUE, Long.MAX_VALUE, Long.MAX_VALUE, Long.MAX_VALUE, Long.MAX_VALUE, Long.MAX_VALUE};
			IloNumVar[] x = cplex.numVarArray(6, lb, ub);
			
			// Profit of having tolls between cities 
			double[] objvals = {(1000 * 2000), (1000 * 2500), (1000 * 3000), (2000 * 2500), (2000 * 3000), (2500 * 3000)};
			
			cplex.addMaximize(cplex.scalProd(x, objvals));
			
			// No of tolls between A and any other city should not exceed 1000 
			cplex.addLe(cplex.sum( x[0],
								   x[1],
								   x[2]), 1000.0);
			
			// No of tolls between B and any other city should not exceed 2000
			cplex.addLe(cplex.sum( x[0],
								   x[3],
								   x[4]), 2000.0);

			// No of tolls between C and any other city should not exceed 2500
			cplex.addLe(cplex.sum( x[1],
								   x[3],
								   x[5]), 2500.0);
			
			// No of tolls between D and any other city should not exceed 3000
			cplex.addLe(cplex.sum( x[2],
								   x[4],
								   x[5]), 3000.0);
			
			if ( cplex.solve() ) 
			{
				System.out.println("Maximum Toll Profit = t * " + (long) cplex.getObjValue());
				double[] val = cplex.getValues(x);
				int ncols = cplex.getNcols();
				for (int j = 0; j < ncols; ++j)
				{
					System.out.println("No. of tolls between cities " + getConnectingCities(j) + " = " + val[j]);
				}
			}
			cplex.end();
		}
		catch (IloException e)
		{
			System.err.println("Concert exception '" + e + "' caught");
		}
	}
	
	public static String getConnectingCities(int n)
	{
		// 0 = AB, 1 = AC, 2 = AD, 3 = BC, 4 = BD, 5 = DC
		switch (n)
		{
			case 0: return "A & B";
			case 1: return "A & C";
			case 2: return "A & D";
			case 3: return "B & C";
			case 4: return "B & D";
			case 5: return "D & C";
			default: return "Error";
		}
	}
}