import Link from "next/link";
import React from "react";

export const Nav = () => {
  return (
    <nav>
      <ul className="flex gap-4 justify-center">
        <li>
          <Link href="/pricefeed"> Prices</Link>
        </li>
        <li>
          <Link href="/tokens"> Lending Tokens</Link>
        </li>
        <li>
          <Link href="credit">Get/Lend Credit</Link>
        </li>
        <li>
          <Link href="swap">Visit Swap</Link>
        </li>
        <li>
          <Link href="liquidity">Manage Liquidity</Link>
        </li>
      </ul>
      {/* <div className=" text-yellow-50 flex flex-col md:flex-row gap-2 md:gap-4 items-center pt-4 px-[2em] justify-between w-full">
        <p className="font-bold text-2xl">TOKENFLOW</p>
        <p className="text-xl font-semibold font-mono shadow-md p-2 m-2">
          {address}
        </p>
        {connection ? (
          <button
            className="border rounded-lg shadow-md border-black bg-white text-purple-950 py-2 px-4 mb-2"
            onClick={disconnectWallet}
          >
            Disconnect
          </button>
        ) : (
          <button
            className="border rounded-lg shadow-md border-black bg-white text-purple-950 py-2 px-4 mb-2"
            onClick={connectWallet}
          >
            Connect Wallet
          </button>
        )}
      </div> */}
    </nav>
  );
};
